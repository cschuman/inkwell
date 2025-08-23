#!/bin/bash

# Create a simple app icon for Inkwell using ImageMagick or sips
# This creates a stylized "I" with markdown-style decorations

echo "Creating Inkwell app icon..."

# Create iconset directory
mkdir -p Inkwell.iconset

# Function to create icon at specific size
create_icon() {
    local size=$1
    local filename=$2
    
    # Use sips (built into macOS) to create a simple icon
    # First create a base image with a solid color
    
    # Create a temporary Python script for generating the icon
    cat > temp_icon.py << 'EOF'
import sys
size = int(sys.argv[1])

# Create an SVG icon
svg_content = f'''<?xml version="1.0" encoding="UTF-8"?>
<svg width="{size}" height="{size}" xmlns="http://www.w3.org/2000/svg">
  <!-- Background -->
  <rect width="{size}" height="{size}" rx="{size//6}" fill="#29232e"/>
  
  <!-- Fountain pen nib shape -->
  <g transform="translate({size//2}, {size//2})">
    <!-- Pen body -->
    <path d="M 0,-{size//3} L -{size//6},-{size//6} L 0,{size//3} L {size//6},-{size//6} Z" 
          fill="#b4b4b9" stroke="#808085" stroke-width="2"/>
    
    <!-- Center slit -->
    <rect x="-2" y="-{size//3}" width="4" height="{size//2}" fill="#29232e"/>
    
    <!-- Ink drop -->
    <circle cx="0" cy="{size//3 + size//10}" r="{size//10}" fill="#007aff" opacity="0.8"/>
    
    <!-- Highlight -->
    <path d="M -{size//8},-{size//4} L -{size//12},0 L -2,0 L -2,-{size//4} Z" 
          fill="#64c8ff" opacity="0.6"/>
  </g>
  
  <!-- Markdown "M" in corner -->
  <text x="{size - size//8}" y="{size - size//12}" 
        font-family="Helvetica" font-size="{size//6}" 
        fill="white" opacity="0.3" text-anchor="end">M</text>
</svg>'''

with open(f'icon_{sys.argv[2]}.svg', 'w') as f:
    f.write(svg_content)
EOF
    
    python3 temp_icon.py $size $filename
    
    # Convert SVG to PNG using sips or rsvg-convert if available
    if command -v rsvg-convert &> /dev/null; then
        rsvg-convert -w $size -h $size icon_$filename.svg -o Inkwell.iconset/icon_$filename.png
    else
        # Fallback: create a simple colored square using sips
        # Create a temporary image with solid color
        echo "Creating fallback icon for $filename..."
        
        # Create a Python script to generate a simple PNG
        cat > temp_png.py << EOF
import struct
import zlib

def create_simple_png(size, filename):
    # Create a simple dark blue square with rounded appearance
    width = height = size
    
    # PNG header
    png_header = b'\x89PNG\r\n\x1a\n'
    
    # IHDR chunk
    ihdr_data = struct.pack('>IIBBBBB', width, height, 8, 6, 0, 0, 0)
    ihdr_crc = zlib.crc32(b'IHDR' + ihdr_data)
    ihdr_chunk = struct.pack('>I', 13) + b'IHDR' + ihdr_data + struct.pack('>I', ihdr_crc)
    
    # Create image data (RGBA)
    image_data = []
    for y in range(height):
        row = [0]  # Filter type
        for x in range(width):
            # Create rounded corners effect
            corner_dist = min(x, y, width-1-x, height-1-y)
            corner_radius = size // 6
            
            if corner_dist < corner_radius:
                # Check if in corner
                cx = corner_radius if x < width//2 else width - corner_radius
                cy = corner_radius if y < height//2 else height - corner_radius
                dx, dy = abs(x - cx), abs(y - cy)
                
                if dx > corner_radius or dy > corner_radius:
                    dist = ((dx - corner_radius)**2 + (dy - corner_radius)**2)**0.5
                    if dist > corner_radius:
                        # Transparent
                        row.extend([0, 0, 0, 0])
                        continue
            
            # Dark background with "I" shape in center
            center_x, center_y = width // 2, height // 2
            
            # Create "I" shape
            if abs(x - center_x) < width // 10:
                # Vertical bar of I
                if abs(y - center_y) < height // 3:
                    # Light blue color for the I
                    row.extend([0, 122, 255, 255])
                else:
                    # Dark background
                    row.extend([41, 42, 48, 255])
            elif abs(y - center_y + height // 3) < height // 12 or abs(y - center_y - height // 3) < height // 12:
                # Top and bottom bars of I
                if abs(x - center_x) < width // 4:
                    # Light blue color
                    row.extend([0, 122, 255, 255])
                else:
                    # Dark background
                    row.extend([41, 42, 48, 255])
            else:
                # Dark background
                row.extend([41, 42, 48, 255])
        
        image_data.append(bytes(row))
    
    # Compress image data
    compressed = zlib.compress(b''.join(image_data))
    
    # IDAT chunk
    idat_crc = zlib.crc32(b'IDAT' + compressed)
    idat_chunk = struct.pack('>I', len(compressed)) + b'IDAT' + compressed + struct.pack('>I', idat_crc)
    
    # IEND chunk
    iend_crc = zlib.crc32(b'IEND')
    iend_chunk = struct.pack('>I', 0) + b'IEND' + struct.pack('>I', iend_crc)
    
    # Write PNG file
    with open(f'Inkwell.iconset/icon_{filename}.png', 'wb') as f:
        f.write(png_header + ihdr_chunk + idat_chunk + iend_chunk)

create_simple_png($size, "$filename")
EOF
        
        python3 temp_png.py
    fi
    
    # Clean up temporary files
    rm -f icon_$filename.svg temp_icon.py temp_png.py
}

# Create all required icon sizes
create_icon 16 "16x16"
create_icon 32 "16x16@2x"
create_icon 32 "32x32"
create_icon 64 "32x32@2x"
create_icon 128 "128x128"
create_icon 256 "128x128@2x"
create_icon 256 "256x256"
create_icon 512 "256x256@2x"
create_icon 512 "512x512"
create_icon 1024 "512x512@2x"

echo "Converting to .icns format..."

# Convert iconset to icns
iconutil -c icns Inkwell.iconset

# Move to resources directory
if [ -f "Inkwell.icns" ]; then
    mv Inkwell.icns resources/Inkwell.icns
    echo "✓ Created resources/Inkwell.icns"
    
    # Clean up
    rm -rf Inkwell.iconset
    echo "✓ Cleaned up temporary files"
else
    echo "✗ Failed to create .icns file"
fi

echo "Icon creation complete!"