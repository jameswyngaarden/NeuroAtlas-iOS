"""
Extract 2D slices from 3D MNI152 template - FULL COVERAGE VERSION
Creates brain images for sagittal, coronal, and axial views with complete coordinate mapping.
"""

import nibabel as nib
import numpy as np
import matplotlib.pyplot as plt
from matplotlib import cm
import json
from pathlib import Path

class BrainSliceExtractor:
    def __init__(self, full_coverage=True):
        self.full_coverage = full_coverage
        
        if not full_coverage:
            # Quick sampling for testing
            self.slice_positions = {
                'sagittal': [-60, -30, 0, 30, 60],    # x coordinates (left-right)
                'coronal': [-60, -30, 0, 30, 60],     # y coordinates (front-back)  
                'axial': [-30, -15, 0, 15, 30]        # z coordinates (bottom-top)
            }
        else:
            # Will be calculated from template dimensions
            self.slice_positions = None
        
    def load_template(self):
        """Load the MNI152 template."""
        template_path = "data/raw/mni152/MNI152_T1_1mm.nii.gz"
        
        if not Path(template_path).exists():
            print(f"❌ Template not found at {template_path}")
            print("Please run download_data.py first")
            return None
            
        print(f"📖 Loading MNI152 template from {template_path}")
        img = nib.load(template_path)
        
        # Get the data and affine transformation matrix
        data = img.get_fdata()
        affine = img.affine
        
        print(f"📏 Template shape: {data.shape}")
        print(f"📐 Voxel dimensions: {img.header.get_zooms()}")
        print(f"🗺️ Affine transform:\n{affine}")
        
        return img, data, affine
    
    def voxel_to_mni(self, voxel_coords, affine):
        """Convert voxel coordinates to MNI coordinates."""
        # Create homogeneous coordinates [x, y, z, 1]
        voxel_homogeneous = np.array([voxel_coords[0], voxel_coords[1], voxel_coords[2], 1])
        
        # Apply affine transformation
        mni_coords = affine @ voxel_homogeneous
        
        # Return MNI coordinates (excluding homogeneous coordinate)
        return mni_coords[:3]
    
    def determine_slice_positions(self, volume_shape, affine):
        """Determine all valid slice positions based on template dimensions."""
        print("🔍 Calculating all possible slice positions...")
        
        # Get the bounds of the template in MNI space
        x_dim, y_dim, z_dim = volume_shape
        
        # Calculate MNI coordinates for each voxel index
        x_positions = []
        y_positions = []
        z_positions = []
        
        # For each dimension, convert voxel indices to MNI coordinates
        for x_idx in range(x_dim):
            mni_coord = self.voxel_to_mni([x_idx, 0, 0], affine)
            x_positions.append(int(round(mni_coord[0])))
        
        for y_idx in range(y_dim):
            mni_coord = self.voxel_to_mni([0, y_idx, 0], affine)
            y_positions.append(int(round(mni_coord[1])))
            
        for z_idx in range(z_dim):
            mni_coord = self.voxel_to_mni([0, 0, z_idx], affine)
            z_positions.append(int(round(mni_coord[2])))
        
        # Remove duplicates and sort
        x_positions = sorted(list(set(x_positions)))
        y_positions = sorted(list(set(y_positions)))  
        z_positions = sorted(list(set(z_positions)))
        
        self.slice_positions = {
            'sagittal': x_positions,
            'coronal': y_positions,
            'axial': z_positions
        }
        
        total_slices = len(x_positions) + len(y_positions) + len(z_positions)
        print(f"📊 Slice positions calculated:")
        print(f"   Sagittal: {len(x_positions)} slices (X: {min(x_positions)} to {max(x_positions)})")
        print(f"   Coronal: {len(y_positions)} slices (Y: {min(y_positions)} to {max(y_positions)})")
        print(f"   Axial: {len(z_positions)} slices (Z: {min(z_positions)} to {max(z_positions)})")
        print(f"   Total: {total_slices} slices")
        
        return total_slices
    
    def mni_to_voxel(self, mni_coords, affine):
        """Convert MNI coordinates to voxel indices."""
        # Create homogeneous coordinates [x, y, z, 1]
        mni_homogeneous = np.array([mni_coords[0], mni_coords[1], mni_coords[2], 1])
        
        # Apply inverse affine transformation
        voxel_coords = np.linalg.inv(affine) @ mni_homogeneous
        
        # Return as integers (voxel indices), excluding the homogeneous coordinate
        return voxel_coords[:3].astype(int)
    
    def extract_slice(self, volume, plane, mni_position, affine):
        """Extract a 2D slice from 3D volume at specified MNI coordinate."""
        
        if plane == 'sagittal':
            # Sagittal slice: fix X coordinate, show Y-Z plane
            mni_coords = [mni_position, 0, 0]
            voxel_coords = self.mni_to_voxel(mni_coords, affine)
            x_idx = voxel_coords[0]
            
            # Extract slice and rotate for proper orientation
            slice_2d = volume[x_idx, :, :]
            slice_2d = np.rot90(slice_2d, k=1)  # Rotate 90 degrees
            
        elif plane == 'coronal':
            # Coronal slice: fix Y coordinate, show X-Z plane
            mni_coords = [0, mni_position, 0]
            voxel_coords = self.mni_to_voxel(mni_coords, affine)
            y_idx = voxel_coords[1]
            
            slice_2d = volume[:, y_idx, :]
            slice_2d = np.rot90(slice_2d, k=1)
            
        elif plane == 'axial':
            # Axial slice: fix Z coordinate, show X-Y plane
            mni_coords = [0, 0, mni_position]
            voxel_coords = self.mni_to_voxel(mni_coords, affine)
            z_idx = voxel_coords[2]
            
            slice_2d = volume[:, :, z_idx]
            slice_2d = np.rot90(slice_2d, k=1)
            
        return slice_2d, voxel_coords
    
    def save_slice_image(self, slice_2d, plane, mni_position, output_dir):
        """Save slice as PNG image with proper contrast."""
        
        # Normalize intensity values for better contrast
        # Remove background (values close to 0)
        slice_clean = slice_2d.copy()
        slice_clean[slice_clean < np.percentile(slice_clean, 10)] = 0
        
        # Enhance contrast
        slice_normalized = np.clip(slice_clean, 
                                  np.percentile(slice_clean, 1), 
                                  np.percentile(slice_clean, 99))
        
        # Normalize to 0-1 range
        if slice_normalized.max() > slice_normalized.min():
            slice_normalized = (slice_normalized - slice_normalized.min()) / (slice_normalized.max() - slice_normalized.min())
        
        # Create figure
        fig, ax = plt.subplots(figsize=(8, 8))
        ax.imshow(slice_normalized, cmap='gray', origin='lower', interpolation='bilinear')
        ax.axis('off')
        
        # Remove all padding and margins
        plt.subplots_adjust(left=0, right=1, top=1, bottom=0)
        
        # Save as PNG
        filename = f"{plane}_{mni_position:+03d}.png"
        output_path = Path(output_dir) / filename
        plt.savefig(output_path, bbox_inches='tight', pad_inches=0, dpi=150, 
                   facecolor='black', edgecolor='none')
        plt.close()
        
        return str(output_path), filename
    
    def create_coordinate_mapping(self, plane, mni_position, slice_shape, affine, voxel_coords):
        """Create coordinate transformation data for the slice."""
        
        mapping = {
            'plane': plane,
            'mni_position': mni_position,
            'slice_shape': list(slice_shape),
            'voxel_coordinates': voxel_coords.tolist(),
            'affine_transform': affine.tolist(),
            'bounds': {
                'x_min': -90, 'x_max': 90,
                'y_min': -126, 'y_max': 90, 
                'z_min': -72, 'z_max': 108
            },
            'description': f"{plane.capitalize()} slice at MNI {plane[0].upper()}={mni_position}"
        }
        
        return mapping
    
    def extract_all_slices(self):
        """Extract all brain slices for the three anatomical planes."""
        
        # Load MNI152 template
        result = self.load_template()
        if result is None:
            return
            
        img, volume, affine = result
        
        # Determine slice positions if doing full coverage
        if self.full_coverage:
            total_slices = self.determine_slice_positions(volume.shape, affine)
            print(f"\n⚠️  Warning: Generating {total_slices} slices will take several minutes...")
            print("   Press Ctrl+C to cancel if needed")
            
            # Ask for confirmation for large jobs
            if total_slices > 200:
                response = input("Continue? (y/n): ")
                if response.lower() != 'y':
                    print("Cancelled.")
                    return
        
        all_mappings = {}
        total_generated = 0
        
        # Process each plane
        for plane in self.slice_positions:
            print(f"\n🔄 Processing {plane} slices...")
            
            plane_mappings = []
            output_dir = f"data/processed/slices/{plane}"
            Path(output_dir).mkdir(parents=True, exist_ok=True)
            
            positions = self.slice_positions[plane]
            
            for i, mni_position in enumerate(positions):
                # Progress indicator for large jobs
                if len(positions) > 50:
                    if i % 20 == 0:
                        print(f"  Progress: {i+1}/{len(positions)} ({((i+1)/len(positions)*100):.1f}%)")
                
                try:
                    # Extract the slice
                    slice_2d, voxel_coords = self.extract_slice(volume, plane, mni_position, affine)
                    
                    # Save as image (NO FILTERING - save all slices including empty ones)
                    image_path, filename = self.save_slice_image(slice_2d, plane, mni_position, output_dir)
                    
                    # Create coordinate mapping
                    mapping = self.create_coordinate_mapping(plane, mni_position, slice_2d.shape, affine, voxel_coords)
                    mapping['image_filename'] = filename
                    mapping['image_path'] = image_path
                    
                    plane_mappings.append(mapping)
                    total_generated += 1
                    
                except Exception as e:
                    print(f"    ⚠️  Error processing {plane} slice at {mni_position}: {e}")
                    continue
            
            all_mappings[plane] = plane_mappings
            print(f"  ✅ {len(plane_mappings)} {plane} slices generated")
        
        # Save coordinate mappings as JSON
        mappings_file = "data/processed/coordinate_mappings.json"
        with open(mappings_file, 'w') as f:
            json.dump(all_mappings, f, indent=2)
        
        print(f"\n💾 Coordinate mappings saved to: {mappings_file}")
        
        # Create a summary file
        self.create_summary(all_mappings, total_generated)
        
        print("✅ Brain slice extraction complete!")
        print(f"📊 Final stats: {total_generated} slices generated (complete coverage)")
        
    def create_summary(self, mappings, total_generated=None):
        """Create a summary of extracted slices."""
        summary_file = "data/processed/extraction_summary.txt"
        
        with open(summary_file, 'w') as f:
            f.write("NeuroAtlas Brain Slice Extraction Summary\n")
            f.write("=" * 50 + "\n\n")
            
            total_slices = 0
            for plane, plane_data in mappings.items():
                f.write(f"{plane.capitalize()} Plane:\n")
                f.write(f"  Number of slices: {len(plane_data)}\n")
                if len(plane_data) > 0:
                    positions = [m['mni_position'] for m in plane_data]
                    f.write(f"  MNI range: {min(positions)} to {max(positions)}\n")
                    f.write(f"  Slice dimensions: {plane_data[0]['slice_shape']}\n")
                f.write("\n")
                total_slices += len(plane_data)
            
            f.write(f"Total slices generated: {total_slices}\n")
            f.write(f"Coverage: Complete MNI coordinate space\n")
            f.write(f"Output directory: data/processed/slices/\n")
            f.write(f"Coordinate mappings: data/processed/coordinate_mappings.json\n")
        
        print(f"📋 Summary saved to: {summary_file}")

def main():
    print("🧠 NeuroAtlas Brain Slice Extractor - FULL COVERAGE")
    print("====================================================")
    
    # Ask user for coverage preference
    print("Choose extraction mode:")
    print("1. Full coverage (all possible slices - ~600+ images)")
    print("2. Sample coverage (15 representative slices)")
    
    choice = input("Enter choice (1 or 2): ").strip()
    
    if choice == "1":
        extractor = BrainSliceExtractor(full_coverage=True)
        print("🚀 Starting FULL coverage extraction...")
    else:
        extractor = BrainSliceExtractor(full_coverage=False)
        print("🚀 Starting sample extraction...")
    
    extractor.extract_all_slices()
    
    print("\n📝 Next Steps:")
    print("1. Check data/processed/slices/ for generated brain images")
    print("2. Review coordinate_mappings.json for coordinate transformation data")
    print("3. Ready to start building the iOS app!")
    
    if choice == "1":
        print("\n🎯 Full coverage complete:")
        print("   - Complete coordinate precision for any point in the brain")
        print("   - Large dataset showcasing data processing capabilities")
        print("   - Professional-grade neuroimaging pipeline")
    else:
        print("\n🎯 Sample coverage complete:")
        print("   - 15 brain slice images (5 per plane)")
        print("   - Quick iteration for app development")
        print("   - Can upgrade to full coverage anytime")

if __name__ == "__main__":
    main()