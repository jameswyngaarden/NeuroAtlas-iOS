#!/usr/bin/env python3
"""
Comprehensive Coordinate System Debug Tool
Identifies spatial transformation issues between brain slices and region masks
"""

import nibabel as nib
import numpy as np
import json
import urllib.request
from pathlib import Path
import matplotlib.pyplot as plt
from PIL import Image

def download_and_analyze_coordinate_mappings():
    """Download coordinate mappings and analyze the coordinate system"""
    url = "https://jameswyngaarden.github.io/NeuroAtlas-iOS/coordinate_mappings.json"
    
    try:
        print("Downloading coordinate mappings...")
        with urllib.request.urlopen(url) as response:
            mappings = json.loads(response.read().decode('utf-8'))
        
        print("SUCCESS: Downloaded coordinate mappings")
        return mappings
    except Exception as e:
        print(f"ERROR: Could not download coordinate mappings: {e}")
        return None

def analyze_test_coordinate(mappings, test_coord=(-25, 9, 52)):
    """Analyze what should happen at the test coordinate"""
    print(f"\nTEST COORDINATE ANALYSIS: {test_coord}")
    print("=" * 50)
    
    x, y, z = test_coord
    
    # Find corresponding slices in each plane
    print("Finding corresponding slices...")
    
    # Sagittal plane (X coordinate)
    sagittal_slices = mappings['sagittal']
    sagittal_slice = None
    for slice_data in sagittal_slices:
        if slice_data['mni_position'] == x:
            sagittal_slice = slice_data
            break
    
    # Coronal plane (Y coordinate)  
    coronal_slices = mappings['coronal']
    coronal_slice = None
    for slice_data in coronal_slices:
        if slice_data['mni_position'] == y:
            coronal_slice = slice_data
            break
            
    # Axial plane (Z coordinate)
    axial_slices = mappings['axial']
    axial_slice = None
    for slice_data in axial_slices:
        if slice_data['mni_position'] == z:
            axial_slice = slice_data
            break
    
    print(f"Sagittal slice (X={x}): {sagittal_slice['image_filename'] if sagittal_slice else 'NOT FOUND'}")
    print(f"Coronal slice (Y={y}): {coronal_slice['image_filename'] if coronal_slice else 'NOT FOUND'}")
    print(f"Axial slice (Z={z}): {axial_slice['image_filename'] if axial_slice else 'NOT FOUND'}")
    
    return sagittal_slice, coronal_slice, axial_slice

def verify_atlas_orientation():
    """Verify Harvard-Oxford atlas orientation and coordinate system"""
    print("\nATLAS ORIENTATION VERIFICATION")
    print("=" * 50)
    
    cortical_path = Path("harvard_oxford_atlases/cortical_maxprob.nii.gz")
    subcortical_path = Path("harvard_oxford_atlases/subcortical_maxprob.nii.gz")
    
    if not cortical_path.exists():
        print("ERROR: Atlas files not found. Run download_atlases.py first.")
        return None, None
    
    # Load atlases
    cortical_img = nib.load(str(cortical_path))
    subcortical_img = nib.load(str(subcortical_path))
    
    cortical_data = cortical_img.get_fdata()
    subcortical_data = subcortical_img.get_fdata()
    
    print(f"Cortical atlas shape: {cortical_data.shape}")
    print(f"Subcortical atlas shape: {subcortical_data.shape}")
    print(f"Cortical max region ID: {int(cortical_data.max())}")
    print(f"Subcortical max region ID: {int(subcortical_data.max())}")
    
    # Check affine transformation
    print(f"\nCortical affine matrix:")
    print(cortical_img.affine)
    
    print(f"\nSubcortical affine matrix:")
    print(subcortical_img.affine)
    
    # Analyze coordinate system
    print(f"\nCoordinate system analysis:")
    print(f"Atlas voxel size: {cortical_img.header.get_zooms()}")
    
    return cortical_data, subcortical_data

def test_coordinate_transformations(cortical_data, subcortical_data, test_mni=(-25, 9, 52)):
    """Test different coordinate transformation approaches"""
    print(f"\nCOORDINATE TRANSFORMATION TESTING")
    print("=" * 50)
    
    x, y, z = test_mni
    atlas_shape = cortical_data.shape
    
    print(f"Testing MNI coordinate: {test_mni}")
    print(f"Atlas shape: {atlas_shape}")
    
    # Method 1: Original mask generation approach
    print(f"\nMethod 1 (Original mask generation):")
    voxel_x1 = int((x + 90) / 2 + 0.5)
    voxel_y1 = int((90 - y) / 2 + 18)
    voxel_z1 = int((z + 72) / 2 + 0.5)
    print(f"  Voxel coordinates: ({voxel_x1}, {voxel_y1}, {voxel_z1})")
    print(f"  Within bounds: X={0 <= voxel_x1 < atlas_shape[0]}, Y={0 <= voxel_y1 < atlas_shape[1]}, Z={0 <= voxel_z1 < atlas_shape[2]}")
    
    # Method 2: Standard MNI-to-voxel conversion
    print(f"\nMethod 2 (Standard MNI conversion):")
    voxel_x2 = int((x + 90) / 2)
    voxel_y2 = int((126 - y) / 2)  
    voxel_z2 = int((z + 72) / 2)
    print(f"  Voxel coordinates: ({voxel_x2}, {voxel_y2}, {voxel_z2})")
    print(f"  Within bounds: X={0 <= voxel_x2 < atlas_shape[0]}, Y={0 <= voxel_y2 < atlas_shape[1]}, Z={0 <= voxel_z2 < atlas_shape[2]}")
    
    # Method 3: FSL standard conversion
    print(f"\nMethod 3 (FSL standard):")
    voxel_x3 = int((x / 2) + 45)
    voxel_y3 = int((-y / 2) + 63)
    voxel_z3 = int((z / 2) + 36)
    print(f"  Voxel coordinates: ({voxel_x3}, {voxel_y3}, {voxel_z3})")
    print(f"  Within bounds: X={0 <= voxel_x3 < atlas_shape[0]}, Y={0 <= voxel_y3 < atlas_shape[1]}, Z={0 <= voxel_z3 < atlas_shape[2]}")
    
    # Test what regions are found at each location
    test_methods = [
        ("Method 1", voxel_x1, voxel_y1, voxel_z1),
        ("Method 2", voxel_x2, voxel_y2, voxel_z2), 
        ("Method 3", voxel_x3, voxel_y3, voxel_z3)
    ]
    
    for method_name, vx, vy, vz in test_methods:
        if (0 <= vx < atlas_shape[0] and 0 <= vy < atlas_shape[1] and 0 <= vz < atlas_shape[2]):
            cortical_value = cortical_data[vx, vy, vz]
            subcortical_value = subcortical_data[vx, vy, vz]
            print(f"  {method_name} regions: Cortical={int(cortical_value)}, Subcortical={int(subcortical_value)}")
        else:
            print(f"  {method_name}: OUT OF BOUNDS")

def analyze_middle_frontal_gyrus_location(cortical_data):
    """Analyze where Middle Frontal Gyrus (region 13) actually appears in the atlas"""
    print(f"\nMIDDLE FRONTAL GYRUS ANALYSIS (Region 13)")
    print("=" * 50)
    
    # Find all voxels containing Middle Frontal Gyrus
    region_mask = (cortical_data == 13)
    region_voxels = np.where(region_mask)
    
    if len(region_voxels[0]) == 0:
        print("ERROR: No Middle Frontal Gyrus voxels found in atlas")
        return
    
    # Calculate extent in each dimension
    x_range = (region_voxels[0].min(), region_voxels[0].max())
    y_range = (region_voxels[1].min(), region_voxels[1].max())
    z_range = (region_voxels[2].min(), region_voxels[2].max())
    
    print(f"Atlas voxel ranges:")
    print(f"  X (sagittal): {x_range}")
    print(f"  Y (coronal): {y_range}")
    print(f"  Z (axial): {z_range}")
    
    # Convert to MNI coordinates using FSL standard
    x_mni_range = (x_range[0] * 2 - 90, x_range[1] * 2 - 90)
    y_mni_range = (126 - y_range[1] * 2, 126 - y_range[0] * 2)
    z_mni_range = (z_range[0] * 2 - 72, z_range[1] * 2 - 72)
    
    print(f"\nExpected MNI coordinate ranges:")
    print(f"  X (left-right): {x_mni_range}")
    print(f"  Y (post-ant): {y_mni_range}")
    print(f"  Z (inf-sup): {z_mni_range}")
    
    # Calculate center of mass
    center_voxel = (
        int(np.mean(region_voxels[0])),
        int(np.mean(region_voxels[1])),
        int(np.mean(region_voxels[2]))
    )
    
    center_mni = (
        center_voxel[0] * 2 - 90,
        126 - center_voxel[1] * 2,
        center_voxel[2] * 2 - 72
    )
    
    print(f"\nMiddle Frontal Gyrus center:")
    print(f"  Atlas voxel: {center_voxel}")
    print(f"  MNI coordinate: {center_mni}")
    
    print(f"\nYour test coordinate (-25, 9, 52) vs expected:")
    print(f"  X: -25 vs {x_mni_range} ({'✓' if x_mni_range[0] <= -25 <= x_mni_range[1] else '✗'})")
    print(f"  Y: 9 vs {y_mni_range} ({'✓' if y_mni_range[0] <= 9 <= y_mni_range[1] else '✗'})")
    print(f"  Z: 52 vs {z_mni_range} ({'✓' if z_mni_range[0] <= 52 <= z_mni_range[1] else '✗'})")

def check_atlas_slice_extraction(cortical_data, test_coord=(-25, 9, 52)):
    """Check what the atlas slice extraction produces"""
    print(f"\nATLAS SLICE EXTRACTION TEST")
    print("=" * 50)
    
    x, y, z = test_coord
    
    # Test FSL standard conversion
    voxel_x = int((x / 2) + 45)
    voxel_y = int((-y / 2) + 63)
    voxel_z = int((z / 2) + 36)
    
    print(f"Testing coordinate: {test_coord}")
    print(f"Converted to voxel: ({voxel_x}, {voxel_y}, {voxel_z})")
    
    atlas_shape = cortical_data.shape
    
    if (0 <= voxel_x < atlas_shape[0] and 0 <= voxel_y < atlas_shape[1] and 0 <= voxel_z < atlas_shape[2]):
        # Extract axial slice (Z=52)
        axial_slice = cortical_data[:, :, voxel_z]
        unique_regions = np.unique(axial_slice)
        unique_regions = unique_regions[unique_regions > 0]  # Remove background
        
        print(f"Axial slice (Z={z}) contains regions: {unique_regions}")
        
        # Check if region 13 (Middle Frontal Gyrus) is present
        if 13 in unique_regions:
            print("✓ Middle Frontal Gyrus (region 13) IS present in this axial slice")
            
            # Find where it appears
            region_13_mask = (axial_slice == 13)
            region_coords = np.where(region_13_mask)
            if len(region_coords[0]) > 0:
                x_coords = region_coords[0]  # X coordinates where region 13 appears
                y_coords = region_coords[1]  # Y coordinates where region 13 appears
                
                print(f"Region 13 appears at voxel coordinates:")
                print(f"  X range: {x_coords.min()} to {x_coords.max()}")
                print(f"  Y range: {y_coords.min()} to {y_coords.max()}")
                
                # Convert back to MNI
                x_mni_range = (x_coords.min() * 2 - 90, x_coords.max() * 2 - 90)
                y_mni_range = (126 - y_coords.max() * 2, 126 - y_coords.min() * 2)
                
                print(f"Converted to MNI coordinates:")
                print(f"  X range: {x_mni_range}")
                print(f"  Y range: {y_mni_range}")
        else:
            print("✗ Middle Frontal Gyrus (region 13) is NOT present in this axial slice")
            print("This explains why no mask is generated!")
    else:
        print("ERROR: Voxel coordinates are out of bounds")

def generate_diagnostic_summary():
    """Generate a comprehensive diagnostic summary"""
    print(f"\nDIAGNOSTIC SUMMARY")
    print("=" * 50)
    
    print("LIKELY ISSUES IDENTIFIED:")
    print("1. COORDINATE SYSTEM MISMATCH:")
    print("   - Your test coordinate (-25, 9, 52) may not contain Middle Frontal Gyrus")
    print("   - The Z=52 coordinate is very high for frontal regions")
    
    print("\n2. ATLAS COORDINATE CONVERSION:")
    print("   - Multiple conversion methods exist")
    print("   - Need to identify which matches your slice generation")
    
    print("\n3. REGION LOOKUP vs ATLAS MISMATCH:")
    print("   - Your region lookup may use different coordinate system than atlas")
    print("   - This could explain wrong region names for coordinates")
    
    print("\nRECOMMENDED FIXES:")
    print("1. Verify region lookup accuracy with known anatomical landmarks")
    print("2. Test multiple coordinate conversion methods")
    print("3. Check if atlas needs spatial transformation/reorientation")
    print("4. Validate that coordinate (-25, 9, 52) actually contains frontal cortex")

def main():
    print("COMPREHENSIVE COORDINATE SYSTEM DEBUG")
    print("=" * 60)
    
    # Download coordinate mappings
    mappings = download_and_analyze_coordinate_mappings()
    if not mappings:
        return
    
    # Analyze test coordinate
    analyze_test_coordinate(mappings)
    
    # Load and verify atlases
    cortical_data, subcortical_data = verify_atlas_orientation()
    if cortical_data is None:
        return
    
    # Test coordinate transformations
    test_coordinate_transformations(cortical_data, subcortical_data)
    
    # Analyze Middle Frontal Gyrus
    analyze_middle_frontal_gyrus_location(cortical_data)
    
    # Check atlas slice extraction
    check_atlas_slice_extraction(cortical_data)
    
    # Generate summary
    generate_diagnostic_summary()
    
    print("\n" + "=" * 60)
    print("DEBUG COMPLETE - Check output above for issues")

if __name__ == '__main__':
    main()
