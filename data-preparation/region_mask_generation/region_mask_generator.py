#!/usr/bin/env python3
"""
Harvard-Oxford Region Mask Generator
Generates transparent PNG overlays for brain regions from Harvard-Oxford atlas
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

class RegionMaskGenerator:
    def __init__(self, atlas_cortical_path, atlas_subcortical_path, output_dir):
        """
        Initialize the region mask generator
        
        Args:
            atlas_cortical_path: Path to Harvard-Oxford cortical atlas (.nii.gz)
            atlas_subcortical_path: Path to Harvard-Oxford subcortical atlas (.nii.gz)
            output_dir: Directory to save region masks
        """
        self.cortical_atlas = nib.load(atlas_cortical_path)
        self.subcortical_atlas = nib.load(atlas_subcortical_path)
        self.cortical_data = self.cortical_atlas.get_fdata()
        self.subcortical_data = self.subcortical_atlas.get_fdata()
        self.output_dir = Path(output_dir)
        
        # Ensure output directories exist
        for plane in ['sagittal', 'coronal', 'axial']:
            for region_id in PRIORITY_REGIONS.keys():
                region_dir = self.output_dir / 'region_masks' / plane / f'region_{region_id:02d}'
                region_dir.mkdir(parents=True, exist_ok=True)
    
    def extract_slice(self, data, plane, slice_index):
        """Extract 2D slice from 3D volume"""
        if plane == 'sagittal':
            return data[slice_index, :, :]
        elif plane == 'coronal':
            return data[:, slice_index, :]
        elif plane == 'axial':
            return data[:, :, slice_index]
        else:
            raise ValueError(f"Unknown plane: {plane}")
    
    def create_region_mask(self, region_data, region_id, threshold=0.25):
        """
        Create binary mask for a specific region
        
        Args:
            region_data: 2D numpy array with region probabilities
            region_id: ID of the region to extract
            threshold: Probability threshold for including voxels
        """
        # For Harvard-Oxford probabilistic atlas, region_id corresponds to the atlas value
        # Extract voxels where this region has probability > threshold
        mask = (region_data == region_id)  # For deterministic atlas
        
        # Alternative for probabilistic atlas:
        # mask = (region_data >= threshold) & (region_data < region_id + 1)
        
        return mask.astype(np.uint8)
    
    def create_transparent_overlay(self, mask, region_id, image_size=(182, 218)):
        """
        Create transparent PNG overlay from binary mask
        
        Args:
            mask: 2D binary mask
            region_id: Region ID for color lookup
            image_size: Output image size (width, height)
        """
        # Resize mask to match brain slice dimensions
        mask_resized = np.array(Image.fromarray(mask * 255).resize(image_size, Image.NEAREST))
        
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
    
    def generate_slice_coordinates(self, plane, atlas_shape):
        """Generate slice coordinates that match your existing slice generation"""
        # FIXED: Generate coordinates to match your 1mm MNI coordinate system
        if plane == 'sagittal':
            # Your range: -91 to +90 (182 slices)
            return range(-91, 91)
        elif plane == 'coronal':  
            # Your range: -126 to +91 (218 slices)
            return range(-126, 92)
        elif plane == 'axial':
            # Your range: -72 to +109 (182 slices)
            return range(-72, 110)
    
    def mni_to_atlas_voxel(self, mni_coord, plane):
        """Convert MNI coordinate to atlas voxel coordinate"""
        if plane == 'sagittal':
            # X: MNI to voxel conversion
            return int((mni_coord + 90) / 2 + 0.5)  # Map -90→+90 to 0→90 voxels
        elif plane == 'coronal':
            # Y: MNI to voxel conversion  
            return int((90 - mni_coord) / 2 + 18)   # Map -126→+90 to 0→108 voxels
        elif plane == 'axial':
            # Z: MNI to voxel conversion
            return int((mni_coord + 72) / 2 + 0.5)  # Map -72→+108 to 0→90 voxels
    
    def generate_masks_for_plane(self, plane):
        """Generate all region masks for a specific anatomical plane"""
        print(f"Generating {plane} masks...")
        
        # FIXED: Use your MNI coordinate system directly
        if plane == 'sagittal':
            mni_coords = range(-91, 91)  # Your actual range
        elif plane == 'coronal':  
            mni_coords = range(-126, 92)  # Your actual range
        elif plane == 'axial':
            mni_coords = range(-72, 110)  # Your actual range
        
        print(f"  Processing {len(mni_coords)} slices from MNI {min(mni_coords)} to {max(mni_coords)}")
        
        for slice_idx, mni_coord in enumerate(mni_coords):
            print(f"  Processing {plane} slice {slice_idx + 1}/{len(mni_coords)} (MNI: {mni_coord})")
            
            # Convert MNI coordinate to atlas voxel coordinate
            atlas_voxel = self.mni_to_atlas_voxel(mni_coord, plane)
            
            # Skip if voxel is outside atlas bounds
            atlas_shape = self.cortical_data.shape
            if plane == 'sagittal' and (atlas_voxel < 0 or atlas_voxel >= atlas_shape[0]):
                continue
            elif plane == 'coronal' and (atlas_voxel < 0 or atlas_voxel >= atlas_shape[1]):
                continue  
            elif plane == 'axial' and (atlas_voxel < 0 or atlas_voxel >= atlas_shape[2]):
                continue
            
            # Extract slices from both atlases
            cortical_slice = self.extract_slice(self.cortical_data, plane, atlas_voxel)
            subcortical_slice = self.extract_slice(self.subcortical_data, plane, atlas_voxel)
            
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
                
                # Create transparent overlay
                overlay_image = self.create_transparent_overlay(mask, region_id)
                
                # FIXED: Generate filename to match your MNI coordinate naming
                filename = f"{plane}_{mni_coord:+03d}.png"
                output_path = self.output_dir / 'region_masks' / plane / f'region_{region_id:02d}' / filename
                
                overlay_image.save(output_path, 'PNG')
                
                print(f"    Saved {region_name} mask: {output_path}")
    
    def mni_to_atlas_voxel(self, mni_coord, plane):
        """Convert MNI coordinate to atlas voxel coordinate"""
        if plane == 'sagittal':
            # X: MNI to voxel conversion  
            return int((mni_coord + 90) / 2 + 0.5)  # Map -90→+90 to 0→90 voxels
        elif plane == 'coronal':
            # Y: MNI to voxel conversion
            return int((90 - mni_coord) / 2 + 18)   # Map -126→+90 to 0→108 voxels
        elif plane == 'axial':
            # Z: MNI to voxel conversion
            return int((mni_coord + 72) / 2 + 0.5)  # Map -72→+108 to 0→90 voxels
    
    def generate_all_masks(self):
        """Generate masks for all planes and priority regions"""
        print(f"Starting region mask generation for {len(PRIORITY_REGIONS)} priority regions...")
        print("Priority regions:")
        for region_id, name in PRIORITY_REGIONS.items():
            color = REGION_COLORS.get(region_id, (255, 255, 255))
            print(f"  {region_id:2d}: {name} (RGB: {color})")
        
        for plane in ['sagittal', 'coronal', 'axial']:
            self.generate_masks_for_plane(plane)
        
        print("✅ Region mask generation complete!")
        
        # Generate summary statistics
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
        
        print(f"\n📊 Summary:")
        print(f"  Total mask files generated: {total_files}")
        print(f"  Total size: {total_size / (1024*1024):.1f} MB")
        print(f"  Average file size: {total_size / total_files / 1024:.1f} KB")

def main():
    parser = argparse.ArgumentParser(description='Generate Harvard-Oxford region masks')
    parser.add_argument('--cortical-atlas', required=True, 
                        help='Path to Harvard-Oxford cortical atlas (.nii.gz)')
    parser.add_argument('--subcortical-atlas', required=True,
                        help='Path to Harvard-Oxford subcortical atlas (.nii.gz)')
    parser.add_argument('--output-dir', required=True,
                        help='Output directory for region masks')
    parser.add_argument('--test-region', type=int,
                        help='Generate masks for only one region (for testing)')
    
    args = parser.parse_args()
    
    # Initialize generator
    generator = RegionMaskGenerator(
        args.cortical_atlas,
        args.subcortical_atlas, 
        args.output_dir
    )
    
    if args.test_region:
        if args.test_region in PRIORITY_REGIONS:
            print(f"🧪 Test mode: generating masks for region {args.test_region} only")
            # Modify PRIORITY_REGIONS to include only test region
            test_region_name = PRIORITY_REGIONS[args.test_region]
            PRIORITY_REGIONS.clear()
            PRIORITY_REGIONS[args.test_region] = test_region_name
        else:
            print(f"❌ Error: Region {args.test_region} not in priority list")
            return
    
    # Generate all masks
    generator.generate_all_masks()

if __name__ == '__main__':
    main()
