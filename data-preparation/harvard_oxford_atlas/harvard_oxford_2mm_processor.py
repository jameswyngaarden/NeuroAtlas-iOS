"""
Harvard-Oxford Atlas Integration for NeuroAtlas iOS App - 2mm Resolution
Processes probabilistic atlas data and creates coordinate-to-region lookup tables.
"""

import nibabel as nib
import numpy as np
import json
from pathlib import Path

# Harvard-Oxford region labels (from FSL)
CORTICAL_REGIONS = {
    0: "Background",
    1: "Frontal Pole",
    2: "Insular Cortex", 
    3: "Superior Frontal Gyrus",
    4: "Middle Frontal Gyrus",
    5: "Inferior Frontal Gyrus, pars triangularis",
    6: "Inferior Frontal Gyrus, pars opercularis",
    7: "Precentral Gyrus",
    8: "Temporal Pole",
    9: "Superior Temporal Gyrus, anterior division",
    10: "Superior Temporal Gyrus, posterior division",
    11: "Middle Temporal Gyrus, anterior division",
    12: "Middle Temporal Gyrus, posterior division",
    13: "Middle Temporal Gyrus, temporooccipital part",
    14: "Inferior Temporal Gyrus, anterior division",
    15: "Inferior Temporal Gyrus, posterior division",
    16: "Inferior Temporal Gyrus, temporooccipital part",
    17: "Postcentral Gyrus",
    18: "Superior Parietal Lobule",
    19: "Supramarginal Gyrus, anterior division",
    20: "Supramarginal Gyrus, posterior division",
    21: "Angular Gyrus",
    22: "Lateral Occipital Cortex, superior division",
    23: "Lateral Occipital Cortex, inferior division",
    24: "Intracalcarine Cortex",
    25: "Frontal Medial Cortex",
    26: "Juxtapositional Lobule Cortex (formerly Supplementary Motor Cortex)",
    27: "Subcallosal Cortex",
    28: "Paracingulate Gyrus",
    29: "Cingulate Gyrus, anterior division",
    30: "Cingulate Gyrus, posterior division",
    31: "Precuneous Cortex",
    32: "Cuneal Cortex",
    33: "Frontal Orbital Cortex",
    34: "Parahippocampal Gyrus, anterior division",
    35: "Parahippocampal Gyrus, posterior division",
    36: "Lingual Gyrus",
    37: "Temporal Fusiform Cortex, anterior division",
    38: "Temporal Fusiform Cortex, posterior division",
    39: "Temporal Occipital Fusiform Cortex",
    40: "Occipital Fusiform Gyrus",
    41: "Frontal Operculum Cortex",
    42: "Central Opercular Cortex",
    43: "Parietal Operculum Cortex",
    44: "Planum Polare",
    45: "Heschl's Gyrus (includes H1 and H2)",
    46: "Planum Temporale",
    47: "Supracalcarine Cortex",
    48: "Occipital Pole"
}

SUBCORTICAL_REGIONS = {
    0: "Background",
    1: "Left Cerebral White Matter",
    2: "Left Cerebral Cortex",
    3: "Left Lateral Ventricle",
    4: "Left Thalamus",
    5: "Left Caudate",
    6: "Left Putamen",
    7: "Left Pallidum",
    8: "3rd Ventricle",
    9: "4th Ventricle",
    10: "Brain Stem",
    11: "Left Hippocampus",
    12: "Left Amygdala",
    13: "Left Accumbens",
    14: "Right Cerebral White Matter",
    15: "Right Cerebral Cortex",
    16: "Right Lateral Ventricle",
    17: "Right Thalamus",
    18: "Right Caudate",
    19: "Right Putamen",
    20: "Right Pallidum",
    21: "Right Hippocampus",
    22: "Right Amygdala",
    23: "Right Accumbens"
}

class HarvardOxfordProcessor:
    def __init__(self):
        self.atlas_dir = Path("harvard_oxford_atlas")
        self.output_dir = Path("../data/processed/regions")
        self.output_dir.mkdir(parents=True, exist_ok=True)
        
    def load_atlas_data(self):
        """Load the Harvard-Oxford atlas files."""
        print("Loading Harvard-Oxford atlas files...")
        
        # Load cortical atlas
        cort_path = self.atlas_dir / "HarvardOxford-cort-maxprob-thr25-1mm.nii.gz"
        sub_path = self.atlas_dir / "HarvardOxford-sub-maxprob-thr25-1mm.nii.gz"
        
        if not cort_path.exists():
            print(f"Cortical atlas not found at {cort_path}")
            print("Please download from NeuroVault or FSL")
            return None, None, None, None
            
        if not sub_path.exists():
            print(f"Subcortical atlas not found at {sub_path}")
            print("Please download from NeuroVault or FSL")
            return None, None, None, None
        
        # Load the NIfTI files
        cort_img = nib.load(cort_path)
        sub_img = nib.load(sub_path)
        
        cort_data = cort_img.get_fdata()
        sub_data = sub_img.get_fdata()
        
        print(f"Cortical atlas shape: {cort_data.shape}")
        print(f"Subcortical atlas shape: {sub_data.shape}")
        
        return cort_data, sub_data, cort_img.affine, sub_img.affine
    
    def mni_to_voxel(self, mni_coords, affine):
        """Convert MNI coordinates to voxel indices."""
        mni_homogeneous = np.array([mni_coords[0], mni_coords[1], mni_coords[2], 1])
        voxel_coords = np.linalg.inv(affine) @ mni_homogeneous
        return voxel_coords[:3].astype(int)
    
    def get_regions_at_coordinate(self, mni_coords, cort_data, sub_data, affine):
        """Get brain regions at a specific MNI coordinate."""
        try:
            voxel_coords = self.mni_to_voxel(mni_coords, affine)
            x, y, z = voxel_coords
            
            # Check bounds
            if (x < 0 or x >= cort_data.shape[0] or 
                y < 0 or y >= cort_data.shape[1] or 
                z < 0 or z >= cort_data.shape[2]):
                return []
            
            regions = []
            
            # Check cortical regions
            cort_label = int(cort_data[x, y, z])
            if cort_label > 0 and cort_label in CORTICAL_REGIONS:
                regions.append({
                    "id": cort_label,
                    "name": CORTICAL_REGIONS[cort_label],
                    "category": "cortical",
                    "probability": 1.0  # maxprob atlas gives binary labels
                })
            
            # Check subcortical regions
            sub_label = int(sub_data[x, y, z])
            if sub_label > 0 and sub_label in SUBCORTICAL_REGIONS:
                regions.append({
                    "id": sub_label + 1000,  # Offset to avoid conflicts
                    "name": SUBCORTICAL_REGIONS[sub_label],
                    "category": "subcortical", 
                    "probability": 1.0
                })
                
            return regions
            
        except Exception as e:
            print(f"Error processing coordinate {mni_coords}: {e}")
            return []
    
    def create_coordinate_grid(self, spacing=2):
        """Create a grid of MNI coordinates for pre-computation at 2mm resolution."""
        # MNI152 standard space bounds
        x_range = range(-90, 91, spacing)
        y_range = range(-126, 91, spacing) 
        z_range = range(-72, 109, spacing)
        
        coordinates = []
        for x in x_range:
            for y in y_range:
                for z in z_range:
                    coordinates.append([x, y, z])
        
        print(f"Generated {len(coordinates)} grid coordinates with {spacing}mm spacing")
        return coordinates
    
    def build_region_lookup_table(self):
        """Build a lookup table mapping coordinates to brain regions at 2mm resolution."""
        print("Building Harvard-Oxford region lookup table at 2mm resolution...")
        
        # Load atlas data
        cort_data, sub_data, cort_affine, sub_affine = self.load_atlas_data()
        if cort_data is None:
            return
        
        # Use cortical affine since they should be the same
        affine = cort_affine
        
        # Create coordinate grid at 2mm spacing
        grid_coords = self.create_coordinate_grid(spacing=2)
        
        # Build lookup table
        lookup_table = {}
        processed = 0
        
        for mni_coords in grid_coords:
            regions = self.get_regions_at_coordinate(mni_coords, cort_data, sub_data, affine)
            
            if regions:  # Only store coordinates that have regions
                coord_key = f"{mni_coords[0]},{mni_coords[1]},{mni_coords[2]}"
                lookup_table[coord_key] = regions
            
            processed += 1
            if processed % 10000 == 0:  # Update progress every 10k coordinates
                print(f"Processed {processed:,}/{len(grid_coords):,} coordinates ({processed/len(grid_coords)*100:.1f}%)")
        
        print(f"Generated lookup table with {len(lookup_table):,} valid coordinates")
        
        # Save lookup table
        output_file = self.output_dir / "harvard_oxford_lookup_2mm.json"
        print(f"Saving lookup table to: {output_file}")
        with open(output_file, 'w') as f:
            json.dump(lookup_table, f, indent=2)
        
        print(f"Saved lookup table to: {output_file}")
        
        # Create region list for iOS app
        self.create_region_list()
        
        return lookup_table
    
    def create_region_list(self):
        """Create a complete list of all regions for the iOS app."""
        all_regions = []
        
        # Add cortical regions
        for region_id, name in CORTICAL_REGIONS.items():
            if region_id > 0:  # Skip background
                all_regions.append({
                    "id": region_id,
                    "name": name,
                    "category": "cortical",
                    "description": f"Cortical region: {name}"
                })
        
        # Add subcortical regions  
        for region_id, name in SUBCORTICAL_REGIONS.items():
            if region_id > 0:  # Skip background
                all_regions.append({
                    "id": region_id + 1000,
                    "name": name,
                    "category": "subcortical",
                    "description": f"Subcortical region: {name}"
                })
        
        # Save region list
        output_file = self.output_dir / "harvard_oxford_regions.json"
        with open(output_file, 'w') as f:
            json.dump(all_regions, f, indent=2)
        
        print(f"Saved region list to: {output_file}")

def main():
    processor = HarvardOxfordProcessor()
    processor.build_region_lookup_table()
    
    print("\nHarvard-Oxford atlas integration complete!")
    print("Next steps:")
    print("1. Copy the JSON files to your iOS app")
    print("2. Update your iOS models to handle region data")
    print("3. Implement region lookup in CoordinateTransformer")

if __name__ == "__main__":
    main()
