#!/bin/bash

# Create Xcode Project Structure Script for VroongFriends

echo "🚀 Creating VroongFriends iOS Project Structure..."

# Project root
PROJECT_ROOT="VroongFriends"

# Create main directory structure
echo "📁 Creating directory structure..."

mkdir -p "$PROJECT_ROOT/App/DI"
mkdir -p "$PROJECT_ROOT/App/Configuration"
mkdir -p "$PROJECT_ROOT/App/Resources"

# Core Layer
mkdir -p "$PROJECT_ROOT/Core/Extensions"
mkdir -p "$PROJECT_ROOT/Core/Utils"
mkdir -p "$PROJECT_ROOT/Core/Base"
mkdir -p "$PROJECT_ROOT/Core/Constants"

# Domain Layer
mkdir -p "$PROJECT_ROOT/Domain/Entities/Order"
mkdir -p "$PROJECT_ROOT/Domain/Entities/User"
mkdir -p "$PROJECT_ROOT/Domain/Entities/Location"
mkdir -p "$PROJECT_ROOT/Domain/Entities/Payment"
mkdir -p "$PROJECT_ROOT/Domain/UseCases/Auth"
mkdir -p "$PROJECT_ROOT/Domain/UseCases/Order"
mkdir -p "$PROJECT_ROOT/Domain/UseCases/Location"
mkdir -p "$PROJECT_ROOT/Domain/UseCases/Payment"
mkdir -p "$PROJECT_ROOT/Domain/Repositories"

# Data Layer
mkdir -p "$PROJECT_ROOT/Data/Repositories"
mkdir -p "$PROJECT_ROOT/Data/DataSources/Remote/API"
mkdir -p "$PROJECT_ROOT/Data/DataSources/Local"
mkdir -p "$PROJECT_ROOT/Data/DTOs/Request"
mkdir -p "$PROJECT_ROOT/Data/DTOs/Response"
mkdir -p "$PROJECT_ROOT/Data/Mappers"

# Presentation Layer
mkdir -p "$PROJECT_ROOT/Presentation/Features/Auth/Login"
mkdir -p "$PROJECT_ROOT/Presentation/Features/Auth/Register"
mkdir -p "$PROJECT_ROOT/Presentation/Features/Order/OrderList"
mkdir -p "$PROJECT_ROOT/Presentation/Features/Order/OrderDetail"
mkdir -p "$PROJECT_ROOT/Presentation/Features/Map"
mkdir -p "$PROJECT_ROOT/Presentation/Features/Chat"
mkdir -p "$PROJECT_ROOT/Presentation/Features/Payment"
mkdir -p "$PROJECT_ROOT/Presentation/Common/Views"
mkdir -p "$PROJECT_ROOT/Presentation/Common/Components"
mkdir -p "$PROJECT_ROOT/Presentation/Common/Modifiers"
mkdir -p "$PROJECT_ROOT/Presentation/Navigation"

# Infrastructure Layer
mkdir -p "$PROJECT_ROOT/Infrastructure/Network"
mkdir -p "$PROJECT_ROOT/Infrastructure/Location"
mkdir -p "$PROJECT_ROOT/Infrastructure/Push"
mkdir -p "$PROJECT_ROOT/Infrastructure/Map"
mkdir -p "$PROJECT_ROOT/Infrastructure/Chat"
mkdir -p "$PROJECT_ROOT/Infrastructure/Security"
mkdir -p "$PROJECT_ROOT/Infrastructure/Analytics"

# Test directories
mkdir -p "${PROJECT_ROOT}Tests/Unit"
mkdir -p "${PROJECT_ROOT}Tests/Integration"
mkdir -p "${PROJECT_ROOT}UITests"

echo "✅ Directory structure created!"

# Create placeholder files
echo "📝 Creating placeholder files..."

# Create .gitkeep files to preserve empty directories
find "$PROJECT_ROOT" -type d -empty -exec touch {}/.gitkeep \;

echo "✅ Placeholder files created!"

echo """
🎉 Project structure created successfully!

Next steps:
1. Open Xcode 16.2
2. Create new iOS App project named 'VroongFriends'
3. Add the created folders to the project
4. Install dependencies:
   - Run 'pod install' for CocoaPods
   - Add SPM packages in Xcode

Directory structure is ready at: $PROJECT_ROOT/
"""