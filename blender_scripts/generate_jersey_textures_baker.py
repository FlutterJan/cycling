"""
===============================================================================
PRO PELOTON MANAGER - PROCEDURAL JERSEY TEXTURE BAKER (BLENDER 5.3)
===============================================================================
Blender 5.3 Python API (bpy + numpy) script that procedurally generates and
bakes 1024x1024 PNG jersey textures to `assets/textures/jerseys/`:

  1. Classification Leader Jerseys (5):
     - jersey_gc_yellow.png          (#D4AF37 General Classification)
     - jersey_points_green.png       (#10B981 Points Classification)
     - jersey_kom_polkadot.png       (#F8FAFC white with #EF4444 red polka dots)
     - jersey_youth_white.png        (#F3F4F6 Best Young Rider)
     - jersey_world_champ_rainbow.png (5 UCI rainbow bands on white base)

  2. Team Pattern Templates (8) — grayscale/luminance-mapped for runtime
     team-color tinting in the 3D engine (primary=1.0, secondary=0.35, trim=0.15):
     - jersey_template_chevron.png          (Szewron / V-stripe)
     - jersey_template_chest_stripe.png     (Pas piersiowy / horizontal band)
     - jersey_template_alpine_gradient.png  (Gradient alpejski / tonal + ridge)
     - jersey_template_vertical_stripes.png (Pasy pionowe)
     - jersey_template_checkerboard.png     (Szachownica)
     - jersey_template_diagonal_sash.png    (Ukośna szarfa)
     - jersey_template_contrast_sleeves.png (Rękawy kontrastowe / raglan yoke)
     - jersey_template_racing_hoops.png     (Podwójne obręcze wyścigowe)

Usage:
  blender --background --python blender_scripts/generate_jersey_textures_baker.py
  blender --background --python blender_scripts/generate_jersey_textures_baker.py -- --output-dir assets/textures/jerseys --size 1024

Compatible with Blender 3.6 LTS, 4.x, and 5.3+.
===============================================================================
"""

import argparse
import os
import struct
import sys
from typing import Dict, List, Tuple, Union

try:
    import bpy
    import numpy as np
except ImportError as exc:
    print(f"[ERROR] Required Blender/NumPy module missing: {exc}")
    print("        Run within Blender:")
    print("        blender --background --python blender_scripts/generate_jersey_textures_baker.py")
    sys.exit(1)


DEFAULT_SIZE = 1024
DEFAULT_OUTPUT_DIR = os.path.join("assets", "textures", "jerseys")

# UCI World Champion 5 rainbow stripes (top-to-bottom: Blue, Red, Black, Yellow, Green)
UCI_RAINBOW_HEX: List[str] = [
    "#0072CE",  # Blue
    "#E10600",  # Red
    "#111827",  # Black
    "#FACC15",  # Yellow
    "#10B981",  # Green
]


# =============================================================================
# COLOR & MATH UTILITIES
# =============================================================================

def hex_to_srgb_rgb(hex_str: str) -> Tuple[float, float, float]:
    """Converts a HEX color string (e.g. '#D4AF37') to normalized sRGB (0..1)."""
    cleaned = hex_str.strip().lstrip("#")
    if len(cleaned) == 3:
        cleaned = "".join(c * 2 for c in cleaned)
    if len(cleaned) != 6:
        raise ValueError(f"Invalid HEX color format: '{hex_str}'")
    r = int(cleaned[0:2], 16) / 255.0
    g = int(cleaned[2:4], 16) / 255.0
    b = int(cleaned[4:6], 16) / 255.0
    return (r, g, b)


def smoothstep(
    edge0: Union[float, np.ndarray],
    edge1: Union[float, np.ndarray],
    x: np.ndarray,
) -> np.ndarray:
    """Hermite smoothstep interpolation for crisp anti-aliased edges."""
    denom = np.asarray(edge1 - edge0, dtype=np.float32)
    num = np.asarray(x - edge0, dtype=np.float32)
    t = np.zeros_like(x, dtype=np.float32)
    np.divide(num, denom, out=t, where=denom != 0.0)
    t = np.where(denom == 0.0, np.where(x >= edge0, 1.0, 0.0), t)
    t = np.clip(t, 0.0, 1.0)
    return (t * t * (3.0 - 2.0 * t)).astype(np.float32)


def blend_layer(
    base: np.ndarray,
    color_rgb: Tuple[float, float, float],
    mask: np.ndarray,
) -> np.ndarray:
    """Alpha-blends an RGB color onto an (H, W, 3) buffer using a (H, W) mask."""
    m = np.clip(mask, 0.0, 1.0)[..., np.newaxis]
    fg = np.array(color_rgb, dtype=np.float32).reshape((1, 1, 3))
    return base * (1.0 - m) + fg * m


def make_uv_grid(size: int) -> Tuple[np.ndarray, np.ndarray]:
    """
    Returns (u, v) coordinate grids of shape (size, size) in [0.0, 1.0].
    Row 0 corresponds to v=0.0 (bottom), row size-1 to v=1.0 (top) to match
    Blender's bpy.data.images pixel buffer orientation.
    """
    lin = np.linspace(0.0, 1.0, size, dtype=np.float32)
    u, v = np.meshgrid(lin, lin)
    return u, v


def compute_lycra_micro_weave(u: np.ndarray, v: np.ndarray, strength: float = 0.014) -> np.ndarray:
    """
    Generates a subtle woven technical-lycra micro-texture modulation around 1.0.
    """
    weave_x = np.sin(u * (2.0 * np.pi * 192.0))
    weave_y = np.sin(v * (2.0 * np.pi * 192.0))
    rib = np.sin(v * (2.0 * np.pi * 48.0)) * 0.35
    return (1.0 + strength * (weave_x * weave_y + rib)).astype(np.float32)


def apply_jersey_structural_details(
    rgb: np.ndarray,
    u: np.ndarray,
    v: np.ndarray,
    trim_rgb: Tuple[float, float, float],
    zipper_rgb: Tuple[float, float, float],
    apply_weave: bool = True,
) -> np.ndarray:
    """
    Applies realistic cycling jersey structural details:
      - Silicone hem gripper band at bottom (v < 0.045)
      - Aero collar trim at top (v > 0.945)
      - Subtle front full-length zipper line at u = 0.5
      - Subtle rear pocket seam hint at v ~ 0.24
      - Technical lycra micro-weave
    """
    out = rgb.copy()

    # Hem gripper & collar trim
    hem_mask = 1.0 - smoothstep(0.040, 0.046, v)
    collar_mask = smoothstep(0.944, 0.950, v)
    out = blend_layer(out, trim_rgb, np.maximum(hem_mask, collar_mask) * 0.92)

    # Subtle zipper placket along u = 0.5 (v >= 0.045)
    zip_dist = np.abs(u - 0.5)
    zip_mask = (1.0 - smoothstep(0.0025, 0.0045, zip_dist)) * smoothstep(0.045, 0.055, v)
    out = blend_layer(out, zipper_rgb, zip_mask * 0.65)

    # Subtle rear pocket horizontal seam at v = 0.24 (on back panel u < 0.22 or u > 0.78)
    seam_dist = np.abs(v - 0.24)
    back_zone = np.maximum(1.0 - smoothstep(0.20, 0.24, u), smoothstep(0.76, 0.80, u))
    seam_mask = (1.0 - smoothstep(0.0015, 0.0035, seam_dist)) * back_zone
    out = blend_layer(out, zipper_rgb, seam_mask * 0.25)

    if apply_weave:
        weave = compute_lycra_micro_weave(u, v)[..., np.newaxis]
        out = np.clip(out * weave, 0.0, 1.0)

    return out


# =============================================================================
# 1. CLASSIFICATION LEADER JERSEYS
# =============================================================================

def generate_solid_leader_jersey(
    u: np.ndarray,
    v: np.ndarray,
    base_hex: str,
    trim_hex: str,
    zipper_hex: str,
) -> np.ndarray:
    """Generates a solid classification leader jersey with subtle seam & trim."""
    base_rgb = hex_to_srgb_rgb(base_hex)
    trim_rgb = hex_to_srgb_rgb(trim_hex)
    zip_rgb = hex_to_srgb_rgb(zipper_hex)

    rgb = np.empty((u.shape[0], u.shape[1], 3), dtype=np.float32)
    rgb[..., 0] = base_rgb[0]
    rgb[..., 1] = base_rgb[1]
    rgb[..., 2] = base_rgb[2]

    # Subtle side-panel tonal shading for athletic contour
    side_dist = np.minimum(np.abs(u - 0.25), np.abs(u - 0.75))
    side_shade = (1.0 - smoothstep(0.03, 0.09, side_dist)) * 0.06
    rgb = rgb * (1.0 - side_shade[..., np.newaxis])

    return apply_jersey_structural_details(rgb, u, v, trim_rgb, zip_rgb)


def generate_kom_polkadot_jersey(u: np.ndarray, v: np.ndarray) -> np.ndarray:
    """
    Generates the King of the Mountains (KOM) jersey:
    Crisp white (#F8FAFC) base with staggered red (#EF4444) polka dots.
    """
    white_rgb = hex_to_srgb_rgb("#F8FAFC")
    red_rgb = hex_to_srgb_rgb("#EF4444")
    dark_red_rgb = hex_to_srgb_rgb("#B91C1C")

    rgb = np.empty((u.shape[0], u.shape[1], 3), dtype=np.float32)
    rgb[..., 0] = white_rgb[0]
    rgb[..., 1] = white_rgb[1]
    rgb[..., 2] = white_rgb[2]

    # Staggered hexagonal polka-dot grid (seamless horizontally in u)
    cols = 10.0
    rows = 10.0
    gx = u * cols
    gy = v * rows
    row_idx = np.floor(gy)
    gx_shifted = gx + (row_idx % 2.0) * 0.5

    # Wrap u-cell distance for seamless horizontal tiling
    fx = (gx_shifted % 1.0) - 0.5
    fy = (gy % 1.0) - 0.5
    dist = np.sqrt(fx * fx + fy * fy)

    dot_radius = 0.23
    aa = 0.025
    dot_mask = 1.0 - smoothstep(dot_radius - aa, dot_radius + aa, dist)

    rgb = blend_layer(rgb, red_rgb, dot_mask)
    return apply_jersey_structural_details(rgb, u, v, red_rgb, dark_red_rgb)


def generate_world_champ_rainbow_jersey(u: np.ndarray, v: np.ndarray) -> np.ndarray:
    """
    Generates the UCI World Champion Rainbow Jersey:
    Clean white (#FFFFFF) base with the 5 official UCI horizontal bands
    (Blue, Red, Black, Yellow, Green) across the chest & torso.
    """
    white_rgb = hex_to_srgb_rgb("#FFFFFF")
    trim_rgb = hex_to_srgb_rgb("#E5E7EB")
    zip_rgb = hex_to_srgb_rgb("#9CA3AF")

    rgb = np.empty((u.shape[0], u.shape[1], 3), dtype=np.float32)
    rgb[..., 0] = white_rgb[0]
    rgb[..., 1] = white_rgb[1]
    rgb[..., 2] = white_rgb[2]

    # 5 horizontal rainbow bands centered on the chest (v from 0.46 to 0.71)
    band_bottom = 0.46
    band_height = 0.05
    aa = 0.0025

    # UCI order top-to-bottom -> reverse for v bottom-to-top
    bands_bottom_to_top = list(reversed(UCI_RAINBOW_HEX))
    for idx, color_hex in enumerate(bands_bottom_to_top):
        y0 = band_bottom + idx * band_height
        y1 = y0 + band_height
        band_mask = smoothstep(y0 - aa, y0 + aa, v) * (1.0 - smoothstep(y1 - aa, y1 + aa, v))
        rgb = blend_layer(rgb, hex_to_srgb_rgb(color_hex), band_mask)

    # Thin rainbow piping at collar (v in [0.955, 0.985])
    collar_band_h = 0.006
    for idx, color_hex in enumerate(bands_bottom_to_top):
        y0 = 0.955 + idx * collar_band_h
        y1 = y0 + collar_band_h
        c_mask = smoothstep(y0 - 0.001, y0 + 0.001, v) * (1.0 - smoothstep(y1 - 0.001, y1 + 0.001, v))
        rgb = blend_layer(rgb, hex_to_srgb_rgb(color_hex), c_mask)

    # Apply structural hem/zipper without overwriting collar rainbow piping
    hem_mask = 1.0 - smoothstep(0.040, 0.046, v)
    rgb = blend_layer(rgb, trim_rgb, hem_mask * 0.9)
    zip_dist = np.abs(u - 0.5)
    zip_mask = (1.0 - smoothstep(0.0025, 0.0045, zip_dist)) * smoothstep(0.045, 0.055, v)
    rgb = blend_layer(rgb, zip_rgb, zip_mask * 0.45)

    weave = compute_lycra_micro_weave(u, v)[..., np.newaxis]
    return np.clip(rgb * weave, 0.0, 1.0)


# =============================================================================
# 2. TEAM PATTERN TEMPLATES (TINTABLE GRAYSCALE MASKS)
# =============================================================================

def _template_to_rgb(
    primary_weight: np.ndarray,
    secondary_mask: np.ndarray,
    u: np.ndarray,
    v: np.ndarray,
) -> np.ndarray:
    """
    Converts a pattern mask into a clean tintable grayscale RGB texture:
      - Primary zone: 0.96 (bright white, tints cleanly to team primary color)
      - Secondary zone: 0.34 (dark contrast, gives distinct two-tone separation)
      - Structural trim/zipper: 0.16
    """
    luminance = primary_weight * (1.0 - secondary_mask) + 0.34 * secondary_mask
    rgb = np.repeat(luminance[..., np.newaxis], 3, axis=2).astype(np.float32)
    return apply_jersey_structural_details(
        rgb,
        u,
        v,
        trim_rgb=(0.16, 0.16, 0.16),
        zipper_rgb=(0.18, 0.18, 0.18),
    )


def generate_template_chevron(u: np.ndarray, v: np.ndarray) -> np.ndarray:
    """1. Szewron (V-Stripe) across chest and back."""
    # Symmetric V-shape centered on u = 0.5 (front) and wrapping around u = 0/1 (back)
    front_dx = np.abs(u - 0.5)
    v_shifted = v + front_dx * 0.65
    band1 = smoothstep(0.68, 0.69, v_shifted) * (1.0 - smoothstep(0.82, 0.83, v_shifted))
    band2 = smoothstep(0.58, 0.59, v_shifted) * (1.0 - smoothstep(0.63, 0.64, v_shifted))
    mask = np.clip(band1 + band2, 0.0, 1.0)
    primary = np.full_like(u, 0.96)
    return _template_to_rgb(primary, mask, u, v)


def generate_template_chest_stripe(u: np.ndarray, v: np.ndarray) -> np.ndarray:
    """2. Pas piersiowy (wide horizontal chest band with crisp pinstripe)."""
    main_band = smoothstep(0.50, 0.506, v) * (1.0 - smoothstep(0.72, 0.726, v))
    top_pin = smoothstep(0.745, 0.750, v) * (1.0 - smoothstep(0.765, 0.770, v))
    bot_pin = smoothstep(0.455, 0.460, v) * (1.0 - smoothstep(0.475, 0.480, v))
    mask = np.clip(main_band + top_pin + bot_pin, 0.0, 1.0)
    primary = np.full_like(u, 0.96)
    return _template_to_rgb(primary, mask, u, v)


def generate_template_alpine_gradient(u: np.ndarray, v: np.ndarray) -> np.ndarray:
    """3. Gradient alpejski (smooth tonal gradient with crisp alpine peak ridge)."""
    # Smooth vertical gradient from bottom (dark) to top (bright)
    grad = np.clip(0.32 + 0.64 * smoothstep(0.10, 0.88, v), 0.32, 0.96)
    # Sharp geometric mountain ridge silhouette across torso
    ridge_h = (
        0.34
        + 0.14 * np.abs(np.sin(u * np.pi * 3.0))
        + 0.06 * np.cos(u * np.pi * 7.0)
    )
    ridge_mask = 1.0 - smoothstep(ridge_h - 0.006, ridge_h + 0.006, v)
    return _template_to_rgb(grad, ridge_mask * 0.65, u, v)


def generate_template_vertical_stripes(u: np.ndarray, v: np.ndarray) -> np.ndarray:
    """4. Pasy pionowe (classic vertical racing stripes)."""
    # 8 seamless vertical stripes around u in [0, 1]
    stripe_wave = np.sin(u * (2.0 * np.pi * 8.0))
    mask = smoothstep(-0.08, 0.08, stripe_wave)
    primary = np.full_like(u, 0.96)
    return _template_to_rgb(primary, mask, u, v)


def generate_template_checkerboard(u: np.ndarray, v: np.ndarray) -> np.ndarray:
    """5. Szachownica (crisp cycling checkerboard pattern)."""
    cells_u = 12.0
    cells_v = 12.0
    su = np.sin(u * np.pi * cells_u)
    sv = np.sin(v * np.pi * cells_v)
    prod = su * sv
    mask = smoothstep(-0.06, 0.06, prod)
    primary = np.full_like(u, 0.96)
    return _template_to_rgb(primary, mask, u, v)


def generate_template_diagonal_sash(u: np.ndarray, v: np.ndarray) -> np.ndarray:
    """6. Ukośna szarfa (bold diagonal sash from shoulder to opposite hip)."""
    # Periodic diagonal distance so it wraps seamlessly around u=0/1
    phase = (u * 1.0 + v * 0.85) % 1.0
    dist = np.minimum(np.abs(phase - 0.5), 1.0 - np.abs(phase - 0.5))
    sash = 1.0 - smoothstep(0.11, 0.125, dist)
    pin = (1.0 - smoothstep(0.155, 0.165, dist)) * smoothstep(0.135, 0.145, dist)
    mask = np.clip(sash + pin, 0.0, 1.0)
    primary = np.full_like(u, 0.96)
    return _template_to_rgb(primary, mask, u, v)


def generate_template_contrast_sleeves(u: np.ndarray, v: np.ndarray) -> np.ndarray:
    """7. Rękawy kontrastowe (raglan shoulder & side-sleeve yoke panels)."""
    # Upper yoke + side sleeve panels in UV space
    upper_yoke = smoothstep(0.73, 0.745, v)
    side_left = 1.0 - smoothstep(0.13, 0.145, np.abs(u - 0.25))
    side_right = 1.0 - smoothstep(0.13, 0.145, np.abs(u - 0.75))
    mask = np.clip(np.maximum(upper_yoke, np.maximum(side_left, side_right)), 0.0, 1.0)
    primary = np.full_like(u, 0.96)
    return _template_to_rgb(primary, mask, u, v)


def generate_template_racing_hoops(u: np.ndarray, v: np.ndarray) -> np.ndarray:
    """8. Podwójne obręcze wyścigowe (twin classic horizontal racing hoops)."""
    hoop1 = smoothstep(0.64, 0.648, v) * (1.0 - smoothstep(0.74, 0.748, v))
    hoop2 = smoothstep(0.46, 0.468, v) * (1.0 - smoothstep(0.56, 0.568, v))
    hoop3 = smoothstep(0.28, 0.288, v) * (1.0 - smoothstep(0.34, 0.348, v))
    mask = np.clip(hoop1 + hoop2 + hoop3, 0.0, 1.0)
    primary = np.full_like(u, 0.96)
    return _template_to_rgb(primary, mask, u, v)


# =============================================================================
# PNG SAVING & VERIFICATION VIA BLENDER IMAGE API
# =============================================================================

def save_rgb_as_png(rgb: np.ndarray, filepath: str) -> None:
    """
    Saves an (H, W, 3) float32 sRGB array to a PNG file using Blender's
    `bpy.data.images` API.
    """
    height, width, _ = rgb.shape
    os.makedirs(os.path.dirname(os.path.abspath(filepath)), exist_ok=True)

    rgba = np.ones((height, width, 4), dtype=np.float32)
    rgba[..., :3] = np.clip(rgb, 0.0, 1.0)
    flat_pixels = rgba.ravel()

    img_name = f"tmp_baker_{os.path.basename(filepath)}"
    existing = bpy.data.images.get(img_name)
    if existing is not None:
        bpy.data.images.remove(existing)

    img = bpy.data.images.new(
        name=img_name,
        width=width,
        height=height,
        alpha=True,
        float_buffer=False,
    )
    try:
        img.colorspace_settings.name = "sRGB"
        img.pixels.foreach_set(flat_pixels)
        img.filepath_raw = os.path.abspath(filepath)
        img.file_format = "PNG"
        img.save()
    finally:
        bpy.data.images.remove(img)


def inspect_png_header(filepath: str) -> Tuple[int, int, int]:
    """Reads PNG IHDR dimensions and returns (width, height, file_size_bytes)."""
    if not os.path.isfile(filepath):
        raise FileNotFoundError(f"Missing PNG file: {filepath}")
    file_size = os.path.getsize(filepath)
    if file_size < 32:
        raise ValueError(f"PNG file too small ({file_size} bytes): {filepath}")
    with open(filepath, "rb") as f:
        header = f.read(24)
    if header[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError(f"Invalid PNG signature in {filepath}")
    if header[12:16] != b"IHDR":
        raise ValueError(f"Missing IHDR chunk in {filepath}")
    width, height = struct.unpack(">II", header[16:24])
    return width, height, file_size


# =============================================================================
# MASTER GENERATION PIPELINE
# =============================================================================

def generate_all_jersey_textures(
    output_dir: str = DEFAULT_OUTPUT_DIR,
    size: int = DEFAULT_SIZE,
) -> Dict[str, Tuple[int, int, int]]:
    """
    Generates all 5 classification leader jerseys and 8 team pattern templates
    into `output_dir` at `size`x`size` resolution.
    Returns a dict mapping filename -> (width, height, file_size_bytes).
    """
    os.makedirs(output_dir, exist_ok=True)
    u, v = make_uv_grid(size)

    generators = {
        # 1. Classification Leader Jerseys (5)
        "jersey_gc_yellow.png": lambda: generate_solid_leader_jersey(
            u, v, base_hex="#D4AF37", trim_hex="#9A7B16", zipper_hex="#785E0E"
        ),
        "jersey_points_green.png": lambda: generate_solid_leader_jersey(
            u, v, base_hex="#10B981", trim_hex="#065F46", zipper_hex="#044E3A"
        ),
        "jersey_kom_polkadot.png": lambda: generate_kom_polkadot_jersey(u, v),
        "jersey_youth_white.png": lambda: generate_solid_leader_jersey(
            u, v, base_hex="#F3F4F6", trim_hex="#D1D5DB", zipper_hex="#9CA3AF"
        ),
        "jersey_world_champ_rainbow.png": lambda: generate_world_champ_rainbow_jersey(u, v),

        # 2. Team Pattern Templates (8)
        "jersey_template_chevron.png": lambda: generate_template_chevron(u, v),
        "jersey_template_chest_stripe.png": lambda: generate_template_chest_stripe(u, v),
        "jersey_template_alpine_gradient.png": lambda: generate_template_alpine_gradient(u, v),
        "jersey_template_vertical_stripes.png": lambda: generate_template_vertical_stripes(u, v),
        "jersey_template_checkerboard.png": lambda: generate_template_checkerboard(u, v),
        "jersey_template_diagonal_sash.png": lambda: generate_template_diagonal_sash(u, v),
        "jersey_template_contrast_sleeves.png": lambda: generate_template_contrast_sleeves(u, v),
        "jersey_template_racing_hoops.png": lambda: generate_template_racing_hoops(u, v),
    }

    results: Dict[str, Tuple[int, int, int]] = {}
    print(f"[JERSEY BAKER] Generating {len(generators)} textures ({size}x{size}) -> {output_dir}")

    for filename, fn in generators.items():
        out_path = os.path.join(output_dir, filename)
        rgb = fn()
        save_rgb_as_png(rgb, out_path)
        w, h, fsize = inspect_png_header(out_path)
        if w != size or h != size:
            raise RuntimeError(f"Dimension mismatch for {filename}: expected {size}x{size}, got {w}x{h}")
        results[filename] = (w, h, fsize)
        print(f"  [OK] {filename:<38} {w}x{h}  ({fsize:,} bytes)")

    print(f"[JERSEY BAKER] Completed: {len(results)}/13 PNG textures verified.")
    return results


def _parse_args(argv: List[str]) -> argparse.Namespace:
    if "--" in argv:
        argv = argv[argv.index("--") + 1:]
    else:
        argv = []
    parser = argparse.ArgumentParser(
        description="Procedural 1024x1024 Jersey Texture Baker for Pro Peloton Manager"
    )
    parser.add_argument(
        "--output-dir",
        default=DEFAULT_OUTPUT_DIR,
        help="Target directory for generated PNG textures.",
    )
    parser.add_argument(
        "--size",
        type=int,
        default=DEFAULT_SIZE,
        help="Square texture resolution in pixels (default: 1024).",
    )
    return parser.parse_args(argv)


def main() -> None:
    args = _parse_args(sys.argv)
    generate_all_jersey_textures(output_dir=args.output_dir, size=args.size)


if __name__ == "__main__":
    main()
