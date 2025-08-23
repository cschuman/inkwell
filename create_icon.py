#!/usr/bin/env python3
"""
Create an app icon for Inkwell - a markdown editor
Icon concept: A stylized fountain pen nib with ink drop
"""

import os
import subprocess
from PIL import Image, ImageDraw, ImageFont
import math

def create_inkwell_icon(size):
    """Create an Inkwell icon at the specified size."""
    # Create a new image with a transparent background
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Define colors
    bg_color = (41, 42, 48, 255)  # Dark background
    ink_color = (0, 122, 255, 255)  # Apple blue
    pen_color = (180, 180, 185, 255)  # Silver/gray for pen
    highlight_color = (100, 200, 255, 255)  # Light blue highlight
    
    # Draw rounded rectangle background
    padding = size // 8
    corner_radius = size // 6
    draw.rounded_rectangle(
        [(0, 0), (size-1, size-1)],
        radius=corner_radius,
        fill=bg_color
    )
    
    # Draw fountain pen nib (simplified geometric design)
    center_x = size // 2
    center_y = size // 2
    
    # Pen nib dimensions
    nib_width = size // 3
    nib_height = size // 2
    
    # Draw pen nib shape (triangle pointing down)
    nib_points = [
        (center_x, center_y - nib_height//3),  # Top center
        (center_x - nib_width//2, center_y - nib_height//3),  # Top left
        (center_x, center_y + nib_height//2),  # Bottom point
        (center_x + nib_width//2, center_y - nib_height//3),  # Top right
    ]
    
    # Draw the main pen nib
    draw.polygon(
        [(nib_points[1]), (nib_points[2]), (nib_points[3])],
        fill=pen_color,
        outline=None
    )
    
    # Draw center slit in pen
    slit_width = size // 40
    draw.rectangle(
        [(center_x - slit_width//2, center_y - nib_height//3),
         (center_x + slit_width//2, center_y + nib_height//3)],
        fill=bg_color
    )
    
    # Draw ink drop
    drop_radius = size // 10
    drop_center_y = center_y + nib_height//2 + drop_radius//2
    
    # Create ink drop with gradient effect
    for i in range(drop_radius, 0, -1):
        alpha = int(255 * (i / drop_radius))
        color = (*ink_color[:3], alpha)
        draw.ellipse(
            [(center_x - i, drop_center_y - i),
             (center_x + i, drop_center_y + i)],
            fill=color
        )
    
    # Add highlight to pen nib
    highlight_points = [
        (center_x - nib_width//4, center_y - nib_height//4),
        (center_x - nib_width//6, center_y),
        (center_x - slit_width, center_y),
        (center_x - slit_width, center_y - nib_height//4),
    ]
    draw.polygon(highlight_points, fill=highlight_color)
    
    # Add "M" for Markdown in the corner (subtle)
    if size >= 128:
        font_size = size // 8
        try:
            # Try to use SF Mono if available
            font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", font_size)
        except:
            font = ImageFont.load_default()
        
        # Draw a subtle "M" in bottom right
        m_text = "M"
        bbox = draw.textbbox((0, 0), m_text, font=font)
        text_width = bbox[2] - bbox[0]
        text_height = bbox[3] - bbox[1]
        
        text_x = size - text_width - padding//2
        text_y = size - text_height - padding//2
        
        # Draw with low opacity
        draw.text((text_x, text_y), m_text, fill=(255, 255, 255, 80), font=font)
    
    return img

def create_iconset():
    """Create all required icon sizes for macOS."""
    # Required sizes for macOS iconset
    sizes = [
        (16, "16x16"),
        (32, "16x16@2x"),
        (32, "32x32"),
        (64, "32x32@2x"),
        (128, "128x128"),
        (256, "128x128@2x"),
        (256, "256x256"),
        (512, "256x256@2x"),
        (512, "512x512"),
        (1024, "512x512@2x"),
    ]
    
    # Create iconset directory
    iconset_dir = "Inkwell.iconset"
    os.makedirs(iconset_dir, exist_ok=True)
    
    print("Creating Inkwell app icon...")
    
    for size, name in sizes:
        icon = create_inkwell_icon(size)
        filename = f"icon_{name}.png"
        filepath = os.path.join(iconset_dir, filename)
        icon.save(filepath, "PNG")
        print(f"  ✓ Created {filename} ({size}x{size})")
    
    # Convert to .icns file
    print("\nConverting to .icns format...")
    try:
        subprocess.run([
            "iconutil", "-c", "icns", iconset_dir
        ], check=True)
        print("  ✓ Created Inkwell.icns")
        
        # Move to resources directory
        if os.path.exists("resources"):
            os.rename("Inkwell.icns", "resources/Inkwell.icns")
            print("  ✓ Moved to resources/Inkwell.icns")
        
        # Clean up iconset directory
        subprocess.run(["rm", "-rf", iconset_dir])
        print("  ✓ Cleaned up temporary files")
        
    except subprocess.CalledProcessError as e:
        print(f"  ✗ Error creating .icns file: {e}")
        print("  Note: iconutil is required (comes with Xcode)")

if __name__ == "__main__":
    # Check for required library
    try:
        from PIL import Image, ImageDraw, ImageFont
    except ImportError:
        print("Installing required library: Pillow")
        subprocess.run(["pip3", "install", "Pillow"], check=True)
        from PIL import Image, ImageDraw, ImageFont
    
    create_iconset()
    print("\nIcon creation complete!")
    print("Next steps:")
    print("1. Update Info.plist to reference 'Inkwell' as CFBundleIconFile")
    print("2. Rebuild the application")