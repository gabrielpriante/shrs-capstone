# Images Directory

This directory contains images and visual assets for the project, including mockups, diagrams, and screenshots.

## How to Add Images

### Option 1: Using GitHub Web Interface (Easiest!)

1. **Navigate to this folder** on GitHub:
   - Go to: `https://github.com/gabrielpriante/shrs-capstone/tree/main/images`
   
2. **Click "Add file" → "Upload files"**
   
3. **Drag and drop your image** or click "choose your files"
   
4. **Add a commit message** (e.g., "Add final product mockup")
   
5. **Click "Commit changes"**

### Option 2: Using Git Command Line

1. **Copy your image file** to this directory:
   ```bash
   cp /path/to/your/image.png /path/to/shrs-capstone/images/
   ```

2. **Stage and commit the image**:
   ```bash
   git add images/your-image.png
   git commit -m "Add final product mockup"
   git push
   ```

### Option 3: Using GitHub Desktop

1. **Copy your image file** to this `images/` folder on your computer
2. **Open GitHub Desktop** - it will automatically detect the new file
3. **Write a commit message** in the bottom left
4. **Click "Commit to main"** (or your current branch)
5. **Click "Push origin"** to upload to GitHub

## Image Naming Guidelines

Use descriptive, lowercase names with hyphens:
- ✅ `final-product-mockup.png`
- ✅ `dashboard-design-v1.jpg`
- ✅ `program-health-interface.png`
- ❌ `Image1.png`
- ❌ `Screenshot 2024-01-27.png`

## Supported Formats

- PNG (`.png`) - Best for screenshots and diagrams
- JPEG (`.jpg`, `.jpeg`) - Best for photos
- GIF (`.gif`) - For simple animations
- SVG (`.svg`) - For vector graphics

## Using Images in Documentation

Once uploaded, you can reference images in markdown files:

```markdown
![Final Product Mockup](images/final-product-mockup.png)
```

Or with a link:
```markdown
[View Final Product Design](images/final-product-mockup.png)
```

## Current Images

<!-- List your images below as you add them -->
- (Add your final product mockup here!)
