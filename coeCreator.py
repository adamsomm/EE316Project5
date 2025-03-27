from PIL import Image

def process_image(input_path, output_image_path, output_coe_path):
    # --- Step 1: Resize/Crop to 256x256 ---
    img = Image.open(input_path)
    width, height = img.size

    # Crop or pad to 256x256
    if width != 256 or height != 256:
        # Crop center if larger
        if width > 256 or height > 256:
            left = (width - 256) // 2
            top = (height - 256) // 2
            img = img.crop((left, top, left + 256, top + 256))
        # Pad with black if smaller
        else:
            new_img = Image.new("RGB", (256, 256), (0, 0, 0))
            new_img.paste(img, ((256 - width) // 2, (256 - height) // 2))
            img = new_img
    
    img.save(output_image_path)
    print(f"Saved 256x256 image to {output_image_path}")

    # --- Step 2: Generate .coe File ---
    img = img.convert("RGB")  # Ensure RGB mode
    with open(output_coe_path, "w") as f:
        f.write("memory_initialization_radix=16;\n")
        f.write("memory_initialization_vector=\n")
        for y in range(256):
            for x in range(256):
                r, g, b = img.getpixel((x, y))
                # Convert to 4-bit per channel (12-bit RGB: RRRRGGGGBBBB)
                r4 = (r >> 4) & 0xF  # Top 4 bits of red
                g4 = (g >> 4) & 0xF  # Top 4 bits of green
                b4 = (b >> 4) & 0xF  # Top 4 bits of blue
                rgb_12bit = (r4 << 8) | (g4 << 4) | b4
                f.write(f"{rgb_12bit:03X}")  # Write as 3-digit hex
                # Add comma unless it's the last pixel
                f.write(",\n" if (x != 255 or y != 255) else ";")
    print(f"Generated .coe file at {output_coe_path}")

# --- Example Usage ---
if __name__ == "__main__":
    input_image = "test_image.jpeg"       # Your input image (any size)
    output_256x256 = "output_256x256.jpg" # Resized 256x256 image
    output_coe = "vga_image.coe"          # COE file for BRAM
    
    process_image(input_image, output_256x256, output_coe)