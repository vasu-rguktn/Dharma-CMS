#!/usr/bin/env python3
"""
Verification script to check if image enhancement routes are properly connected.
Run this from the backend directory: python verify_image_enhancement.py
"""

import sys
from pathlib import Path

# Add backend directory to path
backend_dir = Path(__file__).parent
sys.path.insert(0, str(backend_dir))

def check_imports():
    """Check if all imports work correctly"""
    print("=" * 60)
    print("Checking Imports...")
    print("=" * 60)
    
    try:
        from routers.image_enhancement import router
        print("[OK] Router imported successfully")
        print(f"  - Router prefix: {router.prefix}")
        print(f"  - Router tags: {router.tags}")
    except Exception as e:
        print(f"[FAIL] Failed to import router: {e}")
        return False
    
    try:
        from services.image_enhance_service import enhance_image
        print("[OK] Service function imported successfully")
    except Exception as e:
        print(f"[FAIL] Failed to import service: {e}")
        return False
    
    try:
        from utils.file_utils import read_image, save_temp_image, image_to_base64
        print("[OK] File utilities imported successfully")
    except Exception as e:
        print(f"[FAIL] Failed to import file utils: {e}")
        return False
    
    try:
        from utils.image_utils import (
            denoise, deblur, colorize, sharpen, low_light_boost, upscale
        )
        print("[OK] Image utilities imported successfully")
    except Exception as e:
        print(f"[FAIL] Failed to import image utils: {e}")
        return False
    
    return True

def check_router_registration():
    """Check if router is registered in main.py"""
    print("\n" + "=" * 60)
    print("Checking Router Registration...")
    print("=" * 60)
    
    try:
        from main import app
        print("[OK] FastAPI app imported successfully")
        
        # Check if image_enhancement router is registered
        routes = [route.path for route in app.routes]
        image_enhancement_routes = [r for r in routes if 'image-enhancement' in r]
        
        if image_enhancement_routes:
            print(f"[OK] Image enhancement routes found:")
            for route in image_enhancement_routes:
                print(f"  - {route}")
        else:
            print("[FAIL] No image-enhancement routes found in app")
            return False
        
        # Check for health endpoint
        if any('/health' in r for r in image_enhancement_routes):
            print("[OK] Health check endpoint found")
        else:
            print("[WARN] Health check endpoint not found")
        
        # Check for enhance endpoint
        if any('/enhance' in r for r in image_enhancement_routes):
            print("[OK] Enhance endpoint found")
        else:
            print("[FAIL] Enhance endpoint not found")
            return False
        
        return True
    except Exception as e:
        print(f"[FAIL] Failed to check router registration: {e}")
        import traceback
        traceback.print_exc()
        return False

def check_endpoint_paths():
    """Verify endpoint paths match expected structure"""
    print("\n" + "=" * 60)
    print("Checking Endpoint Paths...")
    print("=" * 60)
    
    try:
        from routers.image_enhancement import router
        
        # Expected paths
        expected_prefix = "/api/image-enhancement"
        expected_health = "/api/image-enhancement/health"
        expected_enhance = "/api/image-enhancement/enhance"
        
        print(f"Expected prefix: {expected_prefix}")
        print(f"Expected health: {expected_health}")
        print(f"Expected enhance: {expected_enhance}")
        
        if router.prefix == expected_prefix:
            print(f"[OK] Router prefix matches: {router.prefix}")
        else:
            print(f"[FAIL] Router prefix mismatch: {router.prefix} != {expected_prefix}")
            return False
        
        # Check routes in router
        route_paths = []
        for route in router.routes:
            if hasattr(route, 'path'):
                route_paths.append(route.path)
        
        print(f"\nFound {len(route_paths)} routes in router:")
        for path in route_paths:
            full_path = f"{router.prefix}{path}"
            print(f"  - {full_path}")
        
        return True
    except Exception as e:
        print(f"✗ Failed to check endpoint paths: {e}")
        import traceback
        traceback.print_exc()
        return False

def check_service_function_signature():
    """Verify service function has correct signature"""
    print("\n" + "=" * 60)
    print("Checking Service Function Signature...")
    print("=" * 60)
    
    try:
        import inspect
        from services.image_enhance_service import enhance_image
        
        sig = inspect.signature(enhance_image)
        params = list(sig.parameters.keys())
        
        required_params = [
            'file', 'denoise_enabled', 'deblur_enabled', 'colorize_enabled',
            'sharpen_enabled', 'low_light_enabled', 'upscale_enabled',
            'denoise_strength', 'deblur_kernel_size', 'colorize_saturation',
            'sharpen_strength', 'low_light_gamma', 'upscale_factor', 'return_base64'
        ]
        
        print(f"Function parameters: {params}")
        
        missing = [p for p in required_params if p not in params]
        if missing:
            print(f"[FAIL] Missing parameters: {missing}")
            return False
        else:
            print("[OK] All required parameters present")
        
        return True
    except Exception as e:
        print(f"[FAIL] Failed to check function signature: {e}")
        return False

def main():
    """Run all checks"""
    print("\n" + "=" * 60)
    print("Image Enhancement Backend Connection Verification")
    print("=" * 60 + "\n")
    
    checks = [
        ("Imports", check_imports),
        ("Router Registration", check_router_registration),
        ("Endpoint Paths", check_endpoint_paths),
        ("Service Function", check_service_function_signature),
    ]
    
    results = []
    for name, check_func in checks:
        try:
            result = check_func()
            results.append((name, result))
        except Exception as e:
            print(f"\n[FAIL] {name} check failed with exception: {e}")
            results.append((name, False))
    
    # Summary
    print("\n" + "=" * 60)
    print("Summary")
    print("=" * 60)
    
    all_passed = True
    for name, result in results:
        status = "[PASS]" if result else "[FAIL]"
        print(f"{status}: {name}")
        if not result:
            all_passed = False
    
    print("\n" + "=" * 60)
    if all_passed:
        print("[OK] All checks passed! Backend is properly connected.")
        return 0
    else:
        print("[FAIL] Some checks failed. Please review the errors above.")
        return 1

if __name__ == "__main__":
    sys.exit(main())
