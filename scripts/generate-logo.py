#!/usr/bin/env python3
"""
FixMyShit Logo Generator
Uses Replicate API (Flux) to generate brand assets

Usage:
    python3 generate-logo.py --all           # Generate all assets
    python3 generate-logo.py --logo          # Main logo only
    python3 generate-logo.py --favicon       # Favicon only
    python3 generate-logo.py --avatar        # Social avatar only
    python3 generate-logo.py --banner        # Banner only
"""

import os
import sys
import argparse
import urllib.request
from pathlib import Path
from datetime import datetime

try:
    import replicate
except ImportError:
    print("Installing replicate...")
    os.system("pip install replicate")
    import replicate

# Output directory
OUTPUT_DIR = Path.home() / "recovery" / "fixmyshit" / "brand"
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

# Brand colors for reference
COLORS = {
    "rage_red": "#E63946",
    "terminal_black": "#1A1A1D", 
    "warning_yellow": "#FFD166",
    "paper_white": "#F8F8F2"
}

# Logo prompts optimized for Flux
ASSETS = {
    "logo_main": {
        "name": "fixmyshit-logo-main",
        "prompt": """Logo design, minimalist stick figure illustration of a developer having a complete meltdown at their computer workstation. Character has exaggerated rage indicators: hair standing vertically, steam clouds shooting from ears, red face, clenched fists raised in frustration. Simple computer monitor shows error icon. A small wrench floats nearby representing the solution. Art style: bold thick black ink outlines, hand-drawn imperfect aesthetic like indie comics or punk zines. Anti-corporate energy. Flat colors only: rage red, terminal black, warning yellow, paper white. No gradients, no 3D effects, no realism. Design must read clearly at small sizes for logo use. Deliberately rough and unpolished.""",
        "aspect_ratio": "1:1",
        "width": 1024,
        "height": 1024
    },
    "logo_split": {
        "name": "fixmyshit-logo-split",
        "prompt": """Split logo illustration, left side: enraged stick figure screaming at broken computer smoke rising, right side: same figure calm and relieved holding wrench with fixed computer showing checkmark, bold thick black ink lines, comic panel style, rage red and terminal black colors, hand-drawn rough aesthetic, punk zine energy, minimalist flat design, no gradients, no 3D, no realism.""",
        "aspect_ratio": "3:2",
        "width": 1536,
        "height": 1024
    },
    "favicon": {
        "name": "fixmyshit-favicon",
        "prompt": """Favicon icon design, extremely simplified angry face, hand-drawn wobbly circle outline, just two dot eyes and jagged mouth showing frustration, steam lines rising from top, bold thick black ink stroke outline, rage red fill color, intentionally imperfect DIY aesthetic, punk zine style, must be legible at 32x32 pixel size, absolutely minimal detail, flat design no gradients no shadows, raw sketch quality.""",
        "aspect_ratio": "1:1",
        "width": 512,
        "height": 512
    },
    "favicon_wrench": {
        "name": "fixmyshit-favicon-wrench",
        "prompt": """Ultra minimal logo icon, angry circle face with wrench through it diagonally, simple dot eyes angry expression, steam lines, bold thick black strokes, red yellow black white only, hand-drawn imperfect, works at favicon size, punk DIY aesthetic, no gradients, no 3D.""",
        "aspect_ratio": "1:1",
        "width": 512,
        "height": 512
    },
    "avatar": {
        "name": "fixmyshit-avatar",
        "prompt": """Square format social media avatar, stick figure developer character screaming in frustration at computer desk, arms raised dramatically, wide open mouth, steam or frustration lines emanating, simple computer monitor with error skull icon, bold thick black brush stroke outlines on white background, accent colors rage red and warning yellow only, hand-drawn intentionally imperfect aesthetic, punk zine DIY energy, high contrast for profile picture visibility, anti-corporate rough sketch style, relatable developer rage moment captured.""",
        "aspect_ratio": "1:1",
        "width": 1024,
        "height": 1024
    },
    "avatar_facepalm": {
        "name": "fixmyshit-avatar-facepalm",
        "prompt": """Square social avatar, simple stick figure in dramatic facepalm pose, head in hands, visible frustration lines radiating, tiny broken computer in background, bold black lines, red and yellow accents on white, hand-drawn imperfect aesthetic, relatable developer energy, punk zine style, no gradients, no 3D.""",
        "aspect_ratio": "1:1",
        "width": 1024,
        "height": 1024
    },
    "banner": {
        "name": "fixmyshit-banner",
        "prompt": """Wide horizontal banner header image 3:1 aspect ratio, comic strip triptych sequence: first panel shows calm stick figure at computer, second panel shows same figure in explosive meltdown with hair standing up steam from ears rage face maximum frustration, third panel shows relieved happy figure holding wrench with fixed computer displaying checkmark, bold thick black ink outlines throughout, color palette limited to rage red warning yellow terminal black paper white, hand-drawn punk zine aesthetic, intentionally rough imperfect brush strokes, flat design no gradients, captures developer emotional journey from calm to rage to relief.""",
        "aspect_ratio": "3:1",
        "width": 1536,
        "height": 512
    },
    "banner_chaos": {
        "name": "fixmyshit-banner-chaos",
        "prompt": """Wide banner header, chaotic scene of stick figure developer surrounded by flying keyboards, error messages, coffee spills, crumpled paper, but center figure holds up wrench triumphantly, order emerging from chaos, bold thick black lines, red yellow accents on white, hand-drawn frantic energy, punk zine aesthetic, anti-corporate, no gradients, no 3D.""",
        "aspect_ratio": "3:1",
        "width": 1536,
        "height": 512
    }
}

def generate_image(asset_key: str, model: str = "black-forest-labs/flux-1.1-pro") -> str:
    """Generate a single image using Replicate API"""
    asset = ASSETS[asset_key]
    print(f"\n🎨 Generating: {asset['name']}")
    print(f"   Prompt: {asset['prompt'][:80]}...")
    
    try:
        output = replicate.run(
            model,
            input={
                "prompt": asset["prompt"],
                "aspect_ratio": asset["aspect_ratio"],
                "output_format": "png",
                "output_quality": 90,
                "safety_tolerance": 5,
                "prompt_upsampling": True
            }
        )
        
        # Handle different output formats
        if isinstance(output, list):
            image_url = output[0]
        else:
            image_url = output
            
        # Download the image
        filename = f"{asset['name']}.png"
        filepath = OUTPUT_DIR / filename
        
        print(f"   Downloading: {image_url}")
        urllib.request.urlretrieve(str(image_url), str(filepath))
        
        print(f"   ✅ Saved: {filepath}")
        return str(filepath)
        
    except Exception as e:
        print(f"   ❌ Error: {e}")
        return None

def main():
    parser = argparse.ArgumentParser(description="Generate FixMyShit brand assets")
    parser.add_argument("--all", action="store_true", help="Generate all assets")
    parser.add_argument("--logo", action="store_true", help="Generate main logos")
    parser.add_argument("--favicon", action="store_true", help="Generate favicons")
    parser.add_argument("--avatar", action="store_true", help="Generate avatars")
    parser.add_argument("--banner", action="store_true", help="Generate banners")
    parser.add_argument("--model", default="black-forest-labs/flux-1.1-pro", help="Replicate model")
    args = parser.parse_args()
    
    # Default to all if nothing specified
    if not any([args.all, args.logo, args.favicon, args.avatar, args.banner]):
        args.all = True
    
    print("=" * 60)
    print("  FixMyShit Logo Generator")
    print("  Using Replicate API + Flux 1.1 Pro")
    print("=" * 60)
    print(f"\nOutput directory: {OUTPUT_DIR}")
    
    assets_to_generate = []
    
    if args.all or args.logo:
        assets_to_generate.extend(["logo_main", "logo_split"])
    if args.all or args.favicon:
        assets_to_generate.extend(["favicon", "favicon_wrench"])
    if args.all or args.avatar:
        assets_to_generate.extend(["avatar", "avatar_facepalm"])
    if args.all or args.banner:
        assets_to_generate.extend(["banner", "banner_chaos"])
    
    print(f"\nGenerating {len(assets_to_generate)} assets...")
    
    results = []
    for asset_key in assets_to_generate:
        result = generate_image(asset_key, args.model)
        results.append((asset_key, result))
    
    # Summary
    print("\n" + "=" * 60)
    print("  GENERATION COMPLETE")
    print("=" * 60)
    
    success = [r for r in results if r[1]]
    failed = [r for r in results if not r[1]]
    
    print(f"\n✅ Successful: {len(success)}")
    for key, path in success:
        print(f"   - {key}: {path}")
    
    if failed:
        print(f"\n❌ Failed: {len(failed)}")
        for key, _ in failed:
            print(f"   - {key}")
    
    print(f"\n📁 All assets in: {OUTPUT_DIR}")

if __name__ == "__main__":
    main()
