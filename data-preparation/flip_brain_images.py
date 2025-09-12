"""
Flip all brain slice images 180 degrees to correct orientation.
This will fix the coordinate system issues by correcting the images at source.
"""

from PIL import Image
import os
from pathlib import Path

def flip_brain_images():
    """Flip all brain slice images 180 degrees."""
    
    # Define the directories containing brain slices
    base_dir = Path("processed/slices")
    
    if not base_dir.exists():
        print(f"Error: {base_dir} not found. Make sure you're in the correct directory.")
        return
    
    # Process each anatomical plane
    planes = ['sagittal', 'coronal', 'axial']
    total_processed = 0
    
    for plane in planes:
        plane_dir = base_dir / plane
        
        if not plane_dir.exists():
            print(f"Warning: {plane_dir} not found, skipping...")
            continue
            
        # Get all PNG files in the directory
        png_files = list(plane_dir.glob("*.png"))
        print(f"Processing {len(png_files)} images in {plane} plane...")
        
        for png_file in png_files:
            try:
                # Open the image
                with Image.open(png_file) as img:
                    # Rotate 180 degrees
                    flipped_img = img.rotate(180)
                    
                    # Save back to the same file
                    flipped_img.save(png_file)
                
                total_processed += 1
                
                # Progress indicator
                if total_processed % 50 == 0:
                    print(f"  Processed {total_processed} images...")
                    
            except Exception as e:
                print(f"Error processing {png_file}: {e}")
                continue
    
    print(f"\nCompleted! Flipped {total_processed} brain images 180 degrees.")
    print("\nNext steps:")
    print("1. Remove .rotationEffect(.degrees(180)) from BrainSliceView.swift")
    print("2. Revert CoordinateTransformer.swift to simple coordinate mapping")
    print("3. Push updated images to GitHub Pages")

def backup_images():
    """Create a backup of original images before flipping."""
    print("Creating backup of original images...")
    
    base_dir = Path("processed/slices")
    backup_dir = Path("processed/slices_backup")
    
    if backup_dir.exists():
        print("Backup already exists, skipping...")
        return
    
    # Copy the entire slices directory
    import shutil
    shutil.copytree(base_dir, backup_dir)
    print(f"Backup created at: {backup_dir}")

def main():
    print("Brain Image Orientation Fix")
    print("=" * 40)
    
    # Ask user if they want to create backup
    response = input("Create backup of original images first? (y/n): ").lower()
    if response == 'y':
        backup_images()
    
    # Confirm before flipping
    response = input("\nProceed with flipping all brain images 180 degrees? (y/n): ").lower()
    if response == 'y':
        flip_brain_images()
    else:
        print("Operation cancelled.")

if __name__ == "__main__":
    main()
