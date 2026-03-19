#!/usr/bin/env python3
"""
upload-gumroad.py - Upload release packages to Gumroad

Usage:
    ./upload-gumroad.py create --name "My Tool" --price 9.99 --files releases/*.zip
    ./upload-gumroad.py update --product-id "abc123" --files releases/*.zip
    ./upload-gumroad.py list

Environment:
    GUMROAD_ACCESS_TOKEN - Your Gumroad API access token
    
Get your token at: https://app.gumroad.com/settings/advanced#application-form
"""

import argparse
import os
import sys
import json
import mimetypes
from pathlib import Path
from typing import Optional

try:
    import requests
except ImportError:
    print("Error: 'requests' library required. Install with: pip install requests")
    sys.exit(1)


GUMROAD_API_BASE = "https://api.gumroad.com/v2"


class GumroadClient:
    """Simple Gumroad API client for product management."""
    
    def __init__(self, access_token: str):
        self.access_token = access_token
        self.session = requests.Session()
    
    def _request(self, method: str, endpoint: str, **kwargs) -> dict:
        """Make an authenticated request to Gumroad API."""
        url = f"{GUMROAD_API_BASE}{endpoint}"
        
        # Add token to data/params
        if 'data' in kwargs:
            kwargs['data']['access_token'] = self.access_token
        elif 'params' in kwargs:
            kwargs['params']['access_token'] = self.access_token
        else:
            kwargs['data'] = {'access_token': self.access_token}
        
        response = self.session.request(method, url, **kwargs)
        
        try:
            result = response.json()
        except json.JSONDecodeError:
            result = {'success': False, 'message': response.text}
        
        if not result.get('success', False):
            raise GumroadError(result.get('message', 'Unknown error'))
        
        return result
    
    def list_products(self) -> list:
        """List all products."""
        result = self._request('GET', '/products', params={})
        return result.get('products', [])
    
    def get_product(self, product_id: str) -> dict:
        """Get a single product."""
        result = self._request('GET', f'/products/{product_id}', params={})
        return result.get('product', {})
    
    def create_product(
        self,
        name: str,
        price: float,
        description: str = "",
        preview_url: str = "",
        require_shipping: bool = False,
        customizable_price: bool = False,
    ) -> dict:
        """Create a new product."""
        data = {
            'name': name,
            'price': int(price * 100),  # Gumroad uses cents
            'description': description,
            'preview_url': preview_url,
            'require_shipping': str(require_shipping).lower(),
            'customizable_price': str(customizable_price).lower(),
        }
        
        result = self._request('POST', '/products', data=data)
        return result.get('product', {})
    
    def update_product(
        self,
        product_id: str,
        name: Optional[str] = None,
        price: Optional[float] = None,
        description: Optional[str] = None,
    ) -> dict:
        """Update an existing product."""
        data = {}
        if name is not None:
            data['name'] = name
        if price is not None:
            data['price'] = int(price * 100)
        if description is not None:
            data['description'] = description
        
        result = self._request('PUT', f'/products/{product_id}', data=data)
        return result.get('product', {})
    
    def delete_product_files(self, product_id: str) -> bool:
        """Delete all files from a product (for clean re-upload)."""
        product = self.get_product(product_id)
        
        for variant in product.get('variants', []):
            for file_info in variant.get('files', []):
                file_id = file_info.get('id')
                if file_id:
                    try:
                        self._request('DELETE', f'/products/{product_id}/files/{file_id}')
                    except GumroadError:
                        pass  # File might already be deleted
        
        return True
    
    def upload_file(self, product_id: str, file_path: Path) -> dict:
        """Upload a file to a product."""
        if not file_path.exists():
            raise FileNotFoundError(f"File not found: {file_path}")
        
        mime_type, _ = mimetypes.guess_type(str(file_path))
        if mime_type is None:
            mime_type = 'application/octet-stream'
        
        # Gumroad file upload endpoint
        url = f"{GUMROAD_API_BASE}/products/{product_id}/files"
        
        with open(file_path, 'rb') as f:
            files = {
                'file': (file_path.name, f, mime_type)
            }
            data = {
                'access_token': self.access_token
            }
            
            response = self.session.post(url, data=data, files=files)
        
        try:
            result = response.json()
        except json.JSONDecodeError:
            raise GumroadError(f"Upload failed: {response.text}")
        
        if not result.get('success', False):
            raise GumroadError(result.get('message', 'Upload failed'))
        
        return result
    
    def enable_product(self, product_id: str) -> dict:
        """Enable a product for sale (publish)."""
        result = self._request('PUT', f'/products/{product_id}/enable')
        return result.get('product', {})
    
    def disable_product(self, product_id: str) -> dict:
        """Disable a product (unpublish)."""
        result = self._request('PUT', f'/products/{product_id}/disable')
        return result.get('product', {})


class GumroadError(Exception):
    """Gumroad API error."""
    pass


def get_access_token() -> str:
    """Get access token from environment."""
    token = os.environ.get('GUMROAD_ACCESS_TOKEN')
    if not token:
        print("Error: GUMROAD_ACCESS_TOKEN environment variable not set")
        print("")
        print("To get your access token:")
        print("1. Go to https://app.gumroad.com/settings/advanced")
        print("2. Scroll to 'Application Form' and create an app")
        print("3. Copy your access token")
        print("4. Set it: export GUMROAD_ACCESS_TOKEN='your_token'")
        sys.exit(1)
    return token


def cmd_list(args):
    """List all products."""
    client = GumroadClient(get_access_token())
    products = client.list_products()
    
    if not products:
        print("No products found.")
        return
    
    print(f"{'ID':<12} {'Name':<30} {'Price':>10} {'Published':<10} URL")
    print("-" * 90)
    
    for p in products:
        price = f"${p.get('price', 0) / 100:.2f}"
        published = "Yes" if p.get('published', False) else "No"
        url = p.get('short_url', 'N/A')
        print(f"{p['id']:<12} {p['name'][:30]:<30} {price:>10} {published:<10} {url}")


def cmd_create(args):
    """Create a new product and upload files."""
    client = GumroadClient(get_access_token())
    
    print(f"Creating product: {args.name}")
    print(f"Price: ${args.price:.2f}")
    
    # Build description
    description = args.description or f"{args.name} - Cross-platform CLI tool"
    
    # Create the product
    product = client.create_product(
        name=args.name,
        price=args.price,
        description=description,
        customizable_price=args.pay_what_you_want,
    )
    
    product_id = product['id']
    print(f"Product created with ID: {product_id}")
    
    # Upload files
    if args.files:
        print(f"\nUploading {len(args.files)} file(s)...")
        for file_path in args.files:
            path = Path(file_path)
            if path.exists():
                print(f"  Uploading: {path.name}...", end=" ")
                try:
                    client.upload_file(product_id, path)
                    print("✓")
                except GumroadError as e:
                    print(f"✗ ({e})")
            else:
                print(f"  Skipping: {path.name} (not found)")
    
    # Optionally publish
    if args.publish:
        client.enable_product(product_id)
        print("\nProduct published!")
    
    print(f"\n✓ Product URL: {product.get('short_url', 'https://gumroad.com/l/' + product_id)}")
    print(f"  Edit at: https://app.gumroad.com/products/{product_id}/edit")


def cmd_update(args):
    """Update an existing product."""
    client = GumroadClient(get_access_token())
    
    product_id = args.product_id
    print(f"Updating product: {product_id}")
    
    # Get current product info
    product = client.get_product(product_id)
    print(f"Current name: {product['name']}")
    
    # Update metadata if provided
    updates = {}
    if args.name:
        updates['name'] = args.name
    if args.price is not None:
        updates['price'] = args.price
    if args.description:
        updates['description'] = args.description
    
    if updates:
        client.update_product(product_id, **updates)
        print("Metadata updated.")
    
    # Replace files if provided
    if args.files:
        if args.replace_files:
            print("Removing existing files...")
            client.delete_product_files(product_id)
        
        print(f"Uploading {len(args.files)} file(s)...")
        for file_path in args.files:
            path = Path(file_path)
            if path.exists():
                print(f"  Uploading: {path.name}...", end=" ")
                try:
                    client.upload_file(product_id, path)
                    print("✓")
                except GumroadError as e:
                    print(f"✗ ({e})")
    
    print(f"\n✓ Product URL: {product.get('short_url')}")


def cmd_upload(args):
    """Upload files to an existing product."""
    client = GumroadClient(get_access_token())
    
    product_id = args.product_id
    print(f"Uploading to product: {product_id}")
    
    if args.replace:
        print("Removing existing files...")
        client.delete_product_files(product_id)
    
    for file_path in args.files:
        path = Path(file_path)
        if path.exists():
            print(f"  Uploading: {path.name}...", end=" ")
            try:
                client.upload_file(product_id, path)
                print("✓")
            except GumroadError as e:
                print(f"✗ ({e})")
        else:
            print(f"  Skipping: {path.name} (not found)")
    
    product = client.get_product(product_id)
    print(f"\n✓ Product URL: {product.get('short_url')}")


def cmd_publish(args):
    """Publish or unpublish a product."""
    client = GumroadClient(get_access_token())
    
    if args.unpublish:
        client.disable_product(args.product_id)
        print(f"Product {args.product_id} unpublished.")
    else:
        product = client.enable_product(args.product_id)
        print(f"Product published: {product.get('short_url')}")


def main():
    parser = argparse.ArgumentParser(
        description="Upload release packages to Gumroad",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # List all your products
  %(prog)s list

  # Create a new product with files
  %(prog)s create --name "My CLI Tool" --price 9.99 --files releases/*.zip

  # Update files on existing product
  %(prog)s update --product-id abc123 --files releases/*.zip --replace-files

  # Just upload new files (keep existing)
  %(prog)s upload --product-id abc123 --files releases/new-file.zip

Environment:
  GUMROAD_ACCESS_TOKEN - Required. Get from https://app.gumroad.com/settings/advanced
        """
    )
    
    subparsers = parser.add_subparsers(dest='command', help='Commands')
    
    # List command
    list_parser = subparsers.add_parser('list', help='List all products')
    list_parser.set_defaults(func=cmd_list)
    
    # Create command
    create_parser = subparsers.add_parser('create', help='Create a new product')
    create_parser.add_argument('--name', '-n', required=True, help='Product name')
    create_parser.add_argument('--price', '-p', type=float, required=True, help='Price in USD')
    create_parser.add_argument('--description', '-d', help='Product description')
    create_parser.add_argument('--files', '-f', nargs='+', help='Files to upload')
    create_parser.add_argument('--publish', action='store_true', help='Publish immediately')
    create_parser.add_argument('--pay-what-you-want', action='store_true', help='Allow custom pricing')
    create_parser.set_defaults(func=cmd_create)
    
    # Update command
    update_parser = subparsers.add_parser('update', help='Update an existing product')
    update_parser.add_argument('--product-id', '-i', required=True, help='Product ID')
    update_parser.add_argument('--name', '-n', help='New product name')
    update_parser.add_argument('--price', '-p', type=float, help='New price in USD')
    update_parser.add_argument('--description', '-d', help='New description')
    update_parser.add_argument('--files', '-f', nargs='+', help='Files to upload')
    update_parser.add_argument('--replace-files', action='store_true', help='Remove existing files first')
    update_parser.set_defaults(func=cmd_update)
    
    # Upload command
    upload_parser = subparsers.add_parser('upload', help='Upload files to a product')
    upload_parser.add_argument('--product-id', '-i', required=True, help='Product ID')
    upload_parser.add_argument('--files', '-f', nargs='+', required=True, help='Files to upload')
    upload_parser.add_argument('--replace', '-r', action='store_true', help='Remove existing files first')
    upload_parser.set_defaults(func=cmd_upload)
    
    # Publish command
    publish_parser = subparsers.add_parser('publish', help='Publish or unpublish a product')
    publish_parser.add_argument('--product-id', '-i', required=True, help='Product ID')
    publish_parser.add_argument('--unpublish', '-u', action='store_true', help='Unpublish instead')
    publish_parser.set_defaults(func=cmd_publish)
    
    args = parser.parse_args()
    
    if not args.command:
        parser.print_help()
        sys.exit(1)
    
    try:
        args.func(args)
    except GumroadError as e:
        print(f"Gumroad API Error: {e}", file=sys.stderr)
        sys.exit(1)
    except KeyboardInterrupt:
        print("\nCancelled.")
        sys.exit(1)


if __name__ == '__main__':
    main()
