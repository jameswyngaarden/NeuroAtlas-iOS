#!/usr/bin/env python3
"""
Coordinate System Diagnostic Tool
Analyzes coordinate system differences between brain slices and region masks
"""

import json
import urllib.request
import os
from pathlib import Path

def download_coordinate_mappings():
    """Download the coordinate mappings to analyze the coordinate system"""
    url = "https://jameswyngaarden.github.io/NeuroAtlas-iOS/coordinate_mappings.json"
    
    try:
        print("📥 Downloading coordinate mappings...")
        with urllib.request.urlopen(url) as response:
            data = json.loads(response.read().decode('utf-8'))
        
        print("✅ Successfully downloaded coordinate mappings")
        return data
    except Exception as e:
        print(f"❌ Error downloading coordinate mappings: {e}")
        return None

def analyze_coordinate_system(mappings):
    """Analyze the coordinate system used in brain slices"""
    print("\n🔍 COORDINATE SYSTEM ANALYSIS")
    print("=" * 50)
    
    for plane in ['sagittal', 'coronal', 'axial']:
        slices = mappings[plane]
        print(f"\n{plane.upper()} PLANE ({len(slices)} slices):")
        
        # Get MNI positions and filenames
        mni_positions = [slice_data['mni_position'] for slice_data in slices]
        filenames = [slice_data['image_filename'] for slice_data in slices]
        
        print(f"  MNI Range: {min(mni_positions)} to {max(mni_positions)}")
        print(f"  MNI Step: {mni_positions[1] - mni_positions[0] if len(mni_positions) > 1 else 'N/A'}")
        
        # Show first 5 slices
        print("  First 5 slices:")
        for i in range(min(5, len(slices))):
            mni_pos = slices[i]['mni_position']
            filename = slices[i]['image_filename']
            print(f"    [{i:2d}] MNI: {mni_pos:+4d} → {filename}")
        
        # Show last 5 slices
        if len(slices) > 5:
            print("  Last 5 slices:")
            for i in range(max(0, len(slices)-5), len(slices)):
                mni_pos = slices[i]['mni_position']
                filename = slices[i]['image_filename']
                print(f"    [{i:2d}] MNI: {mni_pos:+4d} → {filename}")

def generate_expected_mask_filenames(mappings):
    """Generate what mask filenames should be based on brain slice filenames"""
    print("\n🎯 EXPECTED MASK FILENAMES")
    print("=" * 50)
    
    for plane in ['sagittal', 'coronal', 'axial']:
        slices = mappings[plane]
        print(f"\n{plane.upper()} PLANE:")
        print("  Brain Slice → Expected Mask")
        
        for i, slice_data in enumerate(slices[:10]):  # Show first 10
            brain_filename = slice_data['image_filename']
            mni_pos = slice_data['mni_position']
            
            # Generate expected mask filename based on MNI coordinate
            if plane == 'sagittal':
                expected_mask = f"sagittal_{mni_pos:+03d}.png"
            elif plane == 'coronal':
                expected_mask = f"coronal_{mni_pos:+03d}.png"
            else:  # axial
                expected_mask = f"axial_{mni_pos:+03d}.png"
            
            match_status = "✅" if brain_filename == expected_mask else "❌"
            print(f"    {match_status} {brain_filename} → {expected_mask}")

def check_mask_filename_pattern():
    """Check what mask filenames were actually generated"""
    print("\n📁 ACTUAL MASK FILENAMES")
    print("=" * 50)
    
    # This would need to be run locally where you have the mask files
    mask_dir = Path("output/region_masks")
    
    if mask_dir.exists():
        for plane in ['sagittal', 'coronal', 'axial']:
            plane_dir = mask_dir / plane / "region_04"  # Check region 4 masks
            
            if plane_dir.exists():
                mask_files = sorted(list(plane_dir.glob("*.png")))
                print(f"\n{plane.upper()} PLANE - Region 04 masks:")
                
                for i, mask_file in enumerate(mask_files[:10]):  # Show first 10
                    print(f"    [{i:2d}] {mask_file.name}")
            else:
                print(f"\n{plane.upper()} PLANE: No masks found")
    else:
        print("No local mask directory found. Run this script from region-mask-generation directory.")

def generate_coordinate_conversion_analysis():
    """Analyze coordinate conversion between atlas and your coordinate system"""
    print("\n🔄 COORDINATE CONVERSION ANALYSIS")
    print("=" * 50)
    
    print("Standard Harvard-Oxford Atlas Coordinates:")
    print("  - Atlas dimensions: 91 × 109 × 91 voxels")
    print("  - Voxel size: 2mm isotropic")
    print("  - Origin (MNI 0,0,0) at voxel: (45, 63, 36)")
    print("  - MNI range X: -90 to +90mm")
    print("  - MNI range Y: -126 to +90mm") 
    print("  - MNI range Z: -72 to +108mm")
    
    print("\nMask Generation Coordinate Conversion:")
    print("  Sagittal (X): MNI = (voxel - 45) × 2")
    print("  Coronal (Y):  MNI = (63 - voxel) × 2")
    print("  Axial (Z):    MNI = (voxel - 36) × 2")

def suggest_fixes(mappings):
    """Suggest potential fixes based on coordinate analysis"""
    print("\n🔧 SUGGESTED FIXES")
    print("=" * 50)
    
    # Analyze the actual coordinate system
    sagittal_positions = [s['mni_position'] for s in mappings['sagittal']]
    coronal_positions = [s['mni_position'] for s in mappings['coronal']]
    axial_positions = [s['mni_position'] for s in mappings['axial']]
    
    print("Based on your coordinate system:")
    print(f"  Sagittal MNI range: {min(sagittal_positions)} to {max(sagittal_positions)}")
    print(f"  Coronal MNI range:  {min(coronal_positions)} to {max(coronal_positions)}")
    print(f"  Axial MNI range:    {min(axial_positions)} to {max(axial_positions)}")
    
    print("\nPossible issues:")
    print("1. FILENAME MISMATCH:")
    print("   - Your brain slices use different naming than generated masks")
    print("   - Solution: Update mask generation to match your naming")
    
    print("\n2. COORDINATE SYSTEM MISMATCH:")
    print("   - Your slices use different MNI coordinate mapping")
    print("   - Solution: Update mask generation coordinate conversion")
    
    print("\n3. SLICE SELECTION MISMATCH:")
    print("   - Masks generated for different slice positions")
    print("   - Solution: Align slice coordinate ranges")
    
    print("\nTo fix, you'll likely need to:")
    print("1. Update the mask generation script's coordinate conversion")
    print("2. Regenerate masks with correct filename mapping")
    print("3. Ensure slice ranges match between brain images and masks")

def main():
    print("🧠 NeuroAtlas Coordinate System Diagnostic Tool")
    print("=" * 60)
    
    # Download and analyze coordinate mappings
    mappings = download_coordinate_mappings()
    
    if mappings:
        analyze_coordinate_system(mappings)
        generate_expected_mask_filenames(mappings)
        check_mask_filename_pattern()
        generate_coordinate_conversion_analysis()
        suggest_fixes(mappings)
        
        print("\n" + "=" * 60)
        print("📋 NEXT STEPS:")
        print("1. Compare the analysis above with your actual mask filenames")
        print("2. Update the mask generation script if coordinate conversion is wrong")
        print("3. Check iOS app debug output to see what URLs are being requested")
        print("4. Verify mask files exist at the expected URLs")
        
    else:
        print("Could not download coordinate mappings for analysis")

if __name__ == '__main__':
    main()
