#!/usr/bin/env python3
"""
Harvard-Oxford Region Mask Generator with Rotation Options
Generates transparent PNG overlays with spatial orientation corrections
"""

import nibabel as nib
import numpy as np
from PIL import Image, ImageDraw
import os
import json
from pathlib import Path
import argparse

# Top 10 priority regions with their Harvard-Oxford IDs
PRIORITY_REGIONS = {
    # Cortical regions (from Harvard-Oxford cortical atlas)
    4: "Precentral Gyrus",           # Primary motor cortex
    5: "Postcentral Gyrus",          # Primary sensory cortex  
    12: "Superior Frontal Gyrus",    # Executive functions
    13: "Middle Frontal Gyrus",      # Working memory
    
    # Subcortical regions (from Harvard-Oxford subcortical atlas)
    17: "Hippocampus",               # Memory
    18: "Amygdala",                  # Emotion
    5: "Caudate",                    # Motor control (subcortical)
    6: "Putamen",                    # Motor control (subcortical)
    10: "Thalamus",                  # Relay center
    8: "Cerebellum Crus I"           # Motor coordination
}

# Color scheme for each region (RGB values)
REGION_COLORS = {
    4: (255, 0, 0),      # Red - Precentral
    5: (0, 255, 0),      # Green - Postcentral
    12: (0, 0, 255),     # Blue - Superior Frontal
    13: (255, 255, 0),   # Yellow - Middle Frontal
    17: (255, 0, 255),   # Magenta - Hippocampus
    18: (0, 255, 255),   # Cyan - Amygdala
    5: (255, 128, 0),    # Orange - Caudate
    6: (128, 255, 0),    # Lime - Putamen
    10: (255, 0, 128),   # Pink - Thalamus
    8: (128, 0, 255)     # Purple - Cerebellum
}

class RotatedRegionMaskGenerator:
    def __init__(self, atlas_cortical_path, atlas_subcortical_path, output_dir, rotation_degrees=0):
        """
        Initialize the region mask generator with rotation option
        
        Args:
            atlas_cortical_path: Path to Harvard-Oxford cortical atlas (.nii.gz)
            atlas_subcortical_path: Path to Harvard-Oxford subcortical atlas (.nii.gz)
            output_dir: Directory to save region masks
            rotation_degrees: Degrees to rotate masks (0, 90, 180, 270)
        """
        self.cortical_atlas = nib.load(atlas_cortical_path)
        self.subcortical_atlas = nib.load(atlas_subcortical_path)
        self.cortical_data = self.cortical_atlas.get_fdata()
        self.subcortical_data = self.subcortical_atlas.get_fdata()
        self.output_dir = Path(output_dir)
        self.rotation_degrees = rotation_degrees
        
        print(f"Atlas loaded with rotation: {rotation_degrees} degrees")
        print(f"Atlas shape: {self.cortical_data.shape}")
        print(f"Atlas affine:\n{self.cortical_atlas.affine}")
        
        # Ensure output directories exist
        for plane in ['sagittal', 'coronal', 'axial']:
            for region_id in PRIORITY_REGIONS.keys():
                region_dir = self.output_dir / 'region_masks' / plane / f'region_{region_id:02d}'
                region_dir.mkdir(parents=True, exist_ok=True)
    
    def extract_slice(self, data, plane, mni_coord):
        """Extract 2D slice from 3D volume using MNI coordinate"""
        voxel_coord = self.mni_to_atlas_voxel(mni_coord, plane)
        
        if plane == 'sagittal':
            if 0 <= voxel_coord < data.shape[0]:
                return data[voxel_coord, :, :]
        elif plane == 'coronal':
            if 0 <= voxel_coord < data.shape[1]:
                return data[:, voxel_coord, :]
        elif plane == 'axial':
            if 0 <= voxel_coord < data.shape[2]:
                return data[:, :, voxel_coord]
        
        # Return empty slice if out of bounds
        return np.zeros((91, 91))
    
    def mni_to_atlas_voxel(self, mni_coord, plane):
        """Convert MNI coordinate to atlas voxel coordinate using affine transformation"""
        if plane == 'sagittal':
            # X: MNI to voxel using affine matrix
            return int((mni_coord + 90) / 2)
        elif plane == 'coronal':
            # Y: MNI to voxel using affine matrix
            return int((mni_coord + 126) / 2)
        elif plane == 'axial':
            # Z: MNI to voxel using affine matrix
            return int((mni_coord + 72) / 2)
    
    def create_region_mask(self, region_data, region_id, threshold=0.5):
        """Create binary mask for a specific region"""
        # For Harvard-Oxford deterministic atlas, region_id corresponds to the atlas value
        mask = (region_data == region_id)
        return mask.astype(np.uint8)
    
    def rotate_mask(self, mask_array):
        """Rotate mask array by specified degrees"""
        if self.rotation_degrees == 0:
            return mask_array
        elif self.rotation_degrees == 90:
            return np.rot90(mask_array, k=1)  # 90 degrees counterclockwise
        elif self.rotation_degrees == 180:
            return np.rot90(mask_array, k=2)  # 180 degrees
        elif self.rotation_degrees == 270:
            return np.rot90(mask_array, k=3)  # 270 degrees (90 clockwise)
        else:
            print(f"Warning: Unsupported rotation {self.rotation_degrees}. Using 0 degrees.")
            return mask_array
    
    def create_transparent_overlay(self, mask, region_id, image_size=(182, 218)):
        """Create transparent PNG overlay from binary mask with rotation"""
        # Apply rotation to mask
        rotated_mask = self.rotate_mask(mask)
        
        # Resize mask to match brain slice dimensions
        mask_resized = np.array(Image.fromarray(rotated_mask * 255).resize(image_size, Image.NEAREST))
        
        # Create RGBA image (Red, Green, Blue, Alpha)
        rgba_image = np.zeros((image_size[1], image_size[0], 4), dtype=np.uint8)
        
        # Get region color
        color = REGION_COLORS.get(region_id, (255, 255, 255))  # Default to white
        
        # Set color where mask is present
        mask_bool = mask_resized > 127  # Convert to boolean
        rgba_image[mask_bool, 0] = color[0]  # Red channel
        rgba_image[mask_bool, 1] = color[1]  # Green channel  
        rgba_image[mask_bool, 2] = color[2]  # Blue channel
        rgba_image[mask_bool, 3] = 128      # Alpha channel (50% transparency)
        
        return Image.fromarray(rgba_image, 'RGBA')
    
    def generate_masks_for_plane(self, plane):
        """Generate all region masks for a specific anatomical plane"""
        print(f"Generating {plane} masks with {self.rotation_degrees}° rotation...")
        
        # Use your MNI coordinate system directly
        if plane == 'sagittal':
            mni_coords = range(-91, 91)  # Your actual range
        elif plane == 'coronal':  
            mni_coords = range(-126, 92)  # Your actual range
        elif plane == 'axial':
            mni_coords = range(-72, 110)  # Your actual range
        
        print(f"  Processing {len(mni_coords)} slices from MNI {min(mni_coords)} to {max(mni_coords)}")
        
        masks_generated = 0
        
        for slice_idx, mni_coord in enumerate(mni_coords):
            if slice_idx % 20 == 0:  # Progress indicator
                print(f"  Progress: {slice_idx + 1}/{len(mni_coords)} slices")
            
            # Extract slices from both atlases
            cortical_slice = self.extract_slice(self.cortical_data, plane, mni_coord)
            subcortical_slice = self.extract_slice(self.subcortical_data, plane, mni_coord)
            
            # Generate masks for each priority region
            for region_id, region_name in PRIORITY_REGIONS.items():
                # Determine which atlas to use based on region
                if region_id in [4, 5, 12, 13]:  # Cortical regions
                    region_slice = cortical_slice
                else:  # Subcortical regions
                    region_slice = subcortical_slice
                
                # Create binary mask for this region
                mask = self.create_region_mask(region_slice, region_id)
                
                # Skip if no voxels found for this region in this slice
                if not np.any(mask):
                    continue
                
                # Create transparent overlay with rotation
                overlay_image = self.create_transparent_overlay(mask, region_id)
                
                # Generate filename to match your MNI coordinate naming
                filename = f"{plane}_{mni_coord:+03d}.png"
                output_path = self.output_dir / 'region_masks' / plane / f'region_{region_id:02d}' / filename
                
                overlay_image.save(output_path, 'PNG')
                masks_generated += 1
        
        print(f"  Generated {masks_generated} masks for {plane} plane")
    
    def generate_all_masks(self):
        """Generate masks for all planes and priority regions"""
        print(f"Starting region mask generation with {self.rotation_degrees}° rotation...")
        print(f"Priority regions: {len(PRIORITY_REGIONS)}")
        
        for plane in ['sagittal', 'coronal', 'axial']:
            self.generate_masks_for_plane(plane)
        
        print("Region mask generation complete!")
        self.print_summary()
    
    def print_summary(self):
        """Print summary of generated masks"""
        total_files = 0
        total_size = 0
        
        for plane in ['sagittal', 'coronal', 'axial']:
            for region_id in PRIORITY_REGIONS.keys():
                region_dir = self.output_dir / 'region_masks' / plane / f'region_{region_id:02d}'
                if region_dir.exists():
                    files = list(region_dir.glob('*.png'))
                    total_files += len(files)
                    for file in files:
                        total_size += file.stat().st_size
        
        print(f"\nSummary:")
        print(f"  Total mask files generated: {total_files}")
        print(f"  Total size: {total_size / (1024*1024):.1f} MB")
        print(f"  Average file size: {total_size / total_files / 1024:.1f} KB" if total_files > 0 else "  No files generated")
        print(f"  Rotation applied: {self.rotation_degrees}°")

def main():
    parser = argparse.ArgumentParser(description='Generate Harvard-Oxford region masks with rotation')
    parser.add_argument('--cortical-atlas', required=True, 
                        help='Path to Harvard-Oxford cortical atlas (.nii.gz)')
    parser.add_argument('--subcortical-atlas', required=True,
                        help='Path to Harvard-Oxford subcortical atlas (.nii.gz)')
    parser.add_argument('--output-dir', required=True,
                        help='Output directory for region masks')
    parser.add_argument('--rotation', type=int, choices=[0, 90, 180, 270], default=0,
                        help='Rotation in degrees (0, 90, 180, 270). Default: 0')
    parser.add_argument('--test-region', type=int,
                        help='Generate masks for only one region (for testing)')
    
    args = parser.parse_args()
    
    print(f"Region Mask Generator with {args.rotation}° rotation")
    print("=" * 50)
    
    # Initialize generator with rotation
    generator = RotatedRegionMaskGenerator(
        args.cortical_atlas,
        args.subcortical_atlas, 
        args.output_dir,
        rotation_degrees=args.rotation
    )
    
    if args.test_region:
        if args.test_region in PRIORITY_REGIONS:
            print(f"Test mode: generating masks for region {args.test_region} only")
            # Modify PRIORITY_REGIONS to include only test region
            test_region_name = PRIORITY_REGIONS[args.test_region]
            PRIORITY_REGIONS.clear()
            PRIORITY_REGIONS[args.test_region] = test_region_name
        else:
            print(f"Error: Region {args.test_region} not in priority list")
            return
    
    # Generate all masks with rotation
    generator.generate_all_masks()

if __name__ == '__main__':
    main()
