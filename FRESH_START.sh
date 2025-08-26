#!/bin/bash

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}🚀 Fresh Start - New Repository Setup${NC}"
echo "======================================"
echo ""
echo -e "${YELLOW}This will create a clean copy of your project${NC}"
echo -e "${YELLOW}WITHOUT any git history for a fresh start${NC}"
echo ""

# Create a fresh copy directory
FRESH_DIR="../konveyor-n8n-crc-integration"
echo -e "${BLUE}📁 Creating fresh copy at $FRESH_DIR${NC}"

# Remove any existing fresh directory
rm -rf "$FRESH_DIR"

# Create new directory
mkdir -p "$FRESH_DIR"

# Copy all files EXCEPT git history and secrets
echo -e "${BLUE}📋 Copying files (excluding sensitive data)...${NC}"
rsync -av --progress \
  --exclude='.git' \
  --exclude='.env.secrets' \
  --exclude='.secrets' \
  --exclude='*.kubeconfig*' \
  --exclude='crc-kubeconfig.yaml' \
  --exclude='.git.backup' \
  --exclude='git-backup-*' \
  . "$FRESH_DIR/"

# Initialize new git repo
cd "$FRESH_DIR"
echo -e "${BLUE}🎯 Initializing fresh git repository...${NC}"
git init
git branch -M main

# Add all files
git add .

# Create initial commit
echo -e "${BLUE}📝 Creating initial commit...${NC}"
git commit -m "Initial commit - Fresh start with secure configuration

- OpenShift CRC compatible deployment
- Secure secrets management via environment variables  
- No sensitive data in repository
- Complete documentation included"

echo ""
echo -e "${GREEN}✅ SUCCESS! Fresh repository created!${NC}"
echo "======================================"
echo ""
echo -e "${GREEN}📍 Location: $FRESH_DIR${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo ""
echo "1. ${BLUE}Create a new repository on GitHub/GitLab${NC}"
echo "   Go to https://github.com/new"
echo ""
echo "2. ${BLUE}Add the remote and push:${NC}"
echo "   cd $FRESH_DIR"
echo "   git remote add origin <your-new-repo-url>"
echo "   git push -u origin main"
echo ""
echo "3. ${BLUE}Set up secrets:${NC}"
echo "   cp .env.secrets.template .env.secrets"
echo "   # Edit .env.secrets with your credentials"
echo ""
echo "4. ${BLUE}Deploy to CRC:${NC}"
echo "   ./deploy-secure-crc.sh"
echo ""
echo -e "${GREEN}🎉 You now have a clean, secure repository with no history!${NC}"
echo ""
echo -e "${YELLOW}Optional: Archive or delete the old repository${NC}"