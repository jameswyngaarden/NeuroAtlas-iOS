"""
Download MNI152 template and Harvard-Oxford atlas using TemplateFlow.
This script fetches the standard neuroimaging templates needed for the app.
"""

import os
from pathlib import Path
from templateflow import api as tflow
import shutil

def create_directories():
    """Create necessary directory structure."""
    directories = [
        'data/raw/mni152',
        'data/raw/harvard_oxford',
        'data/processed/slices/sagittal',
        'data/processed/slices/coronal', 
        'data/processed/slices/axial',
        'data/processed/atlases',
        'data/api-ready'
    ]
    
    for directory in directories:
        Path(directory).mkdir(parents=True, exist_ok=True)
    print("✅ Directory structure created")

def download_mni152_template():
    """Download the MNI152 T1 1mm template using TemplateFlow."""
    print("📡 Downloading MNI152 template...")
    
    try:
        # Download MNI152NLin6Asym template (1mm resolution)
        template_files = tflow.get('MNI152NLin6Asym', 
                                  resolution=1,
                                  suffix='T1w')
        
        # Handle case where templateflow returns a list
        if isinstance(template_files, list):
            # Use the first file (usually the main template)
            template_file = template_files[0]
            print(f"📁 TemplateFlow returned {len(template_files)} files, using: {template_file}")
        else:
            template_file = template_files
        
        # Copy to our data directory
        target_path = "data/raw/mni152/MNI152_T1_1mm.nii.gz"
        shutil.copy2(template_file, target_path)
        
        print(f"✅ MNI152 template downloaded to: {target_path}")
        print(f"   Source: {template_file}")
        
        return target_path
        
    except Exception as e:
        print(f"❌ Error downloading MNI152 template: {e}")
        
        # Try a more specific query
        try:
            print("Trying more specific template query...")
            template_files = tflow.get('MNI152NLin6Asym', 
                                      resolution=1,
                                      desc=None,
                                      suffix='T1w')
            
            if isinstance(template_files, list):
                # Look for the main template (not brain-extracted)
                main_template = None
                for file in template_files:
                    if 'desc-brain' not in str(file):
                        main_template = file
                        break
                
                if main_template is None:
                    main_template = template_files[0]  # fallback to first file
                    
                template_file = main_template
            else:
                template_file = template_files
            
            target_path = "data/raw/mni152/MNI152_T1_1mm.nii.gz"
            shutil.copy2(template_file, target_path)
            
            print(f"✅ MNI152 template downloaded to: {target_path}")
            return target_path
            
        except Exception as e2:
            print(f"❌ Could not download any MNI152 template: {e2}")
            return None

def download_harvard_oxford_atlas():
    """Download Harvard-Oxford atlas using TemplateFlow."""
    print("📡 Downloading Harvard-Oxford atlas...")
    
    try:
        # TemplateFlow doesn't have Harvard-Oxford directly
        # We'll note this and provide an alternative approach
        print("📝 Note: Harvard-Oxford atlas not available in TemplateFlow")
        print("    We'll create a simplified atlas from the MNI152 template")
        print("    For production use, you would obtain Harvard-Oxford from FSL")
        
        # For now, we'll work with what we have and create regions later
        atlas_dir = "data/raw/harvard_oxford"
        Path(atlas_dir).mkdir(parents=True, exist_ok=True)
        
        # Create a placeholder file to indicate we need the real atlas
        with open(f"{atlas_dir}/README.txt", "w") as f:
            f.write("Harvard-Oxford atlas files should be placed here:\n")
            f.write("- HarvardOxford-cort-maxprob-thr25-1mm.nii.gz\n")
            f.write("- HarvardOxford-sub-maxprob-thr25-1mm.nii.gz\n")
            f.write("- Available from FSL installation or NeuroVault\n")
        
        print("✅ Atlas directory prepared")
        return True
        
    except Exception as e:
        print(f"❌ Error setting up atlas directory: {e}")
        return False

def main():
    print("🧠 NeuroAtlas Data Download")
    print("============================")
    
    create_directories()
    
    # Download MNI152 template
    template_path = download_mni152_template()
    
    # Set up atlas directory
    atlas_success = download_harvard_oxford_atlas()
    
    if template_path:
        print("\n✅ Data download completed successfully!")
        print(f"📂 Template location: {template_path}")
        print("\n📝 Next Steps:")
        print("1. Run extract_slices.py to generate brain slices")
        print("2. The app will work with the MNI152 template")
        print("3. (Optional) Add Harvard-Oxford atlas for detailed regions")
    else:
        print("\n❌ Could not download required data")
        print("Please check your internet connection and try again")

if __name__ == "__main__":
    main()