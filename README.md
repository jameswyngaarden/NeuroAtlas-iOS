# NeuroAtlas-iOS
An interactive neuroanatomy learning app for iOS that transforms complex brain imaging data into an intuitive touch-based learning experience. Built with industry-standard neuroimaging datasets and modern iOS development practices.

![iOS](https://img.shields.io/badge/iOS-15.0+-blue.svg)
![Swift](https://img.shields.io/badge/Swift-5.7+-orange.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)
![Status](https://img.shields.io/badge/Status-In%20Development-yellow.svg)

## Features

- **Interactive Brain Visualization**: Explore anatomical brain slices in sagittal, coronal, and axial planes
- **Real-time Coordinate Mapping**: Touch any point to see precise MNI coordinates and anatomical regions
- **Harvard-Oxford Atlas Integration**: Industry-standard brain region identification with probability mapping
- **Manual Coordinate Entry**: Jump to specific MNI coordinates for targeted exploration
- **Offline-Capable**: Core functionality works without internet connection after initial data load
- **Modern iOS Design**: Built with SwiftUI and follows Apple's Human Interface Guidelines

## Target Users

- **Medical students** learning neuroanatomy
- **Neuroscience researchers** needing quick anatomical reference
- **Healthcare professionals** reviewing brain anatomy
- **Anyone curious** about brain structure and organization

## Technical Highlights

### iOS Development
- **Swift 5.7+** with SwiftUI for modern, declarative UI
- **MVVM architecture** for clean separation of concerns
- **Core Graphics** for custom coordinate transformation
- **URLSession** with async/await for modern networking
- **Comprehensive unit tests** for coordinate mathematics

### Data Processing Pipeline
- **Python-based preprocessing** using nibabel and numpy
- **MNI152 template** (1mm resolution) for standardized brain space
- **Harvard-Oxford probabilistic atlas** for region identification
- **Custom coordinate transformation algorithms** for pixel-to-MNI mapping
- **Optimized image formats** for mobile performance

### Professional Development Practices
- **Modular architecture** with clear separation between data, business logic, and UI
- **Error handling** and graceful degradation for network issues
- **Performance optimization** with image caching and background loading
- **Comprehensive documentation** and inline code comments
- **Git workflow** with meaningful commit messages and branching strategy

## Getting Started

### Prerequisites

- **macOS** with Xcode 14.0 or later
- **iOS device or simulator** running iOS 15.0+
- **Python 3.8+** for data preparation scripts
- **Git** for version control

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/NeuroAtlas-iOS.git
   cd NeuroAtlas-iOS
   ```

2. **Set up data preparation environment**
   ```bash
   cd data-preparation
   pip install -r requirements.txt
   ```

3. **Download and process neuroimaging data**
   ```bash
   python download_data.py
   python extract_slices.py
   python generate_atlases.py
   ```

4. **Open iOS project**
   ```bash
   cd ../ios-app
   open NeuroAtlas.xcodeproj
   ```

5. **Build and run**
   - Select your target device in Xcode
   - Press ⌘+R to build and run

## 📁 Project Structure

```
NeuroAtlas-iOS/
├── 📂 data-preparation/     # Python scripts for neuroimaging data processing
│   ├── download_data.py     # Fetch MNI152 template and atlases
│   ├── extract_slices.py    # Generate 2D brain slices from 3D volumes
│   └── generate_atlases.py  # Create region lookup tables
├── 📂 ios-app/             # Native iOS application
│   ├── Models/             # Data models and coordinate systems
│   ├── ViewModels/         # Business logic and state management
│   ├── Views/              # SwiftUI user interface components
│   └── Services/           # Networking and data processing
├── 📂 docs/                # Technical documentation
└── 📂 scripts/             # Automation and deployment scripts
```

## Core Technologies

### Neuroimaging Standards
- **MNI152 Template**: Montreal Neurological Institute standardized brain template
- **Harvard-Oxford Atlas**: Probabilistic cortical and subcortical region maps
- **MNI Coordinate System**: Standard stereotactic space for neuroscience research

### iOS Development Stack
- **SwiftUI**: Modern declarative UI framework
- **Combine**: Reactive programming for data flow
- **Core Graphics**: Custom drawing and coordinate transformation
- **XCTest**: Unit and UI testing framework

### Data Processing
- **nibabel**: Neuroimaging file format handling
- **NumPy**: Numerical computing for image processing
- **Matplotlib**: Visualization for slice generation

## Educational Value

This project demonstrates several key computer science and software engineering concepts:

- **Computer Graphics**: 2D/3D coordinate transformations and image processing
- **Mobile Development**: Native iOS app architecture and performance optimization
- **Data Processing**: Scientific data pipeline development with Python
- **API Design**: RESTful services for serving processed neuroimaging data
- **Software Architecture**: Clean code principles and modular design patterns
- **Testing**: Unit testing for mathematical computations and UI interactions

## Contributing

Contributions are welcome! This project is designed to showcase modern development practices while remaining educational and accessible.

### Development Workflow
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes with clear, descriptive commits
4. Add tests for new functionality
5. Submit a pull request with detailed description

### Areas for Contribution
- Additional brain atlases (e.g., AAL, Destrieux)
- 3D visualization features
- Advanced quiz/learning modes
- Performance optimizations
- Accessibility improvements

## Documentation

- [**Development Guide**](docs/DEVELOPMENT.md) - Detailed setup and development instructions
- [**API Documentation**](docs/API_DOCUMENTATION.md) - Backend service specifications  
- [**Coordinate Systems**](docs/COORDINATE_SYSTEMS.md) - Mathematical foundations and transformations
- [**Architecture Overview**](docs/ARCHITECTURE.md) - System design and component interactions

## Project Goals

### Technical Objectives
- ✅ Demonstrate proficiency in iOS development with Swift/SwiftUI
- ✅ Show understanding of coordinate transformations and computer graphics
- ✅ Build end-to-end data processing pipeline
- ✅ Implement clean architecture and testing practices
- 🔄 Deploy scalable backend services
- 🔄 Publish to App Store

### Learning Outcomes
- **Mobile Development**: Complete iOS app development lifecycle
- **Scientific Computing**: Real-world data processing with Python
- **Computer Graphics**: Coordinate systems and geometric transformations
- **Software Engineering**: Professional development practices and architecture
- **Domain Knowledge**: Neuroanatomy and brain imaging fundamentals

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- **FSL Team** at FMRIB for the MNI152 template and Harvard-Oxford atlas
- **NiBabel contributors** for neuroimaging file format support
- **Apple Developer Documentation** for iOS development guidelines
- **Neuroinformatics community** for open science data sharing

## Contact

**Project Creator**: Jimmy Wyngaarden  
**Email**: james.wyngaarden@temple.edu
**LinkedIn**: [[LinkedIn Profile]](https://www.linkedin.com/in/jimmy-wyngaarden-00233877/)  
**Portfolio**: [[Website]](https://jameswyngaarden.github.io/)

---

*Built with ❤️ for neuroscience education and iOS development learning*
