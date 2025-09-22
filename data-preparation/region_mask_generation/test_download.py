#!/usr/bin/env python3
import os
from pathlib import Path
import nibabel as nib

try:
    from nilearn import datasets
    
    print("📥 Downloading Harvard-Oxford atlases via nilearn...")
    
    # Create directory
    atlas_dir = Path("harvard_oxford_atlases")
    atlas_dir.mkdir(exist_ok=True)
    
    # Download cortical atlas
    print("  Downloading cortical atlas...")
    atlas_cort = datasets.fetch_atlas_harvard_oxford('cort-maxprob-thr25-2mm')
    
    # Save cortical atlas
    cortical_path = atlas_dir / 'cortical_maxprob.nii.gz'
    nib.save(atlas_cort.maps, str(cortical_path))
    
    # Download subcortical atlas  
    print("  Downloading subcortical atlas...")
    atlas_sub = datasets.fetch_atlas_harvard_oxford('sub-maxprob-thr25-2mm')
    
    # Save subcortical atlas
    subcortical_path = atlas_dir / 'subcortical_maxprob.nii.gz'
    nib.save(atlas_sub.maps, str(subcortical_path))
    
    # Check file sizes
    print("\n📊 Downloaded files:")
    for file in atlas_dir.glob('*.nii.gz'):
        size_mb = file.stat().st_size / (1024 * 1024)
        print(f"  ✅ {file.name}: {size_mb:.1f} MB")
    
    # Test loading to verify
    print("\n🔍 Verifying atlas files...")
    cortical_img = nib.load(str(cortical_path))
    subcortical_img = nib.load(str(subcortical_path))
    
    cortical_data = cortical_img.get_fdata()
    subcortical_data = subcortical_img.get_fdata()
    
    print(f"  Cortical atlas: shape {cortical_data.shape}, max region ID {int(cortical_data.max())}")
    print(f"  Subcortical atlas: shape {subcortical_data.shape}, max region ID {int(subcortical_data.max())}")
    
    print("\n🎉 Success! Atlases downloaded and verified")
    print("\n🚀 Now you can run:")
    print("python region_mask_generator.py \\")
    print("  --cortical-atlas harvard_oxford_atlases/cortical_maxprob.nii.gz \\")
    print("  --subcortical-atlas harvard_oxford_atlases/subcortical_maxprob.nii.gz \\")
    print("  --output-dir ./output \\")
    print("  --test-region 4")
    
except ImportError as e:
    print(f"❌ Missing package: {e}")
    print("Install with: pip install nilearn nibabel")
except Exception as e:
    print(f"❌ Error: {e}")
    import traceback
    traceback.print_exc()
