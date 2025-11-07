#!/bin/bash

# Master Test Runner for CAPSTONE Project
set -e

echo "Ì∫Ä CAPSTONE PROJECT COMPREHENSIVE TEST SUITE"
echo "============================================"
echo "Starting all validation tests..."
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}[MASTER] $1${NC}"; }

# Test 1: WebAdmin Access
log "1. RUNNING WEBADMIN ACCESS TESTS"
if ./test-webadmin-access.sh; then
    echo -e "${GREEN}‚úÖ WebAdmin tests passed${NC}"
else
    echo -e "${RED}‚ùå WebAdmin tests failed${NC}"
    exit 1
fi

echo ""
log "2. RUNNING DBADMIN ACCESS TESTS"
if ./test-dbadmin-access.sh; then
    echo -e "${GREEN}‚úÖ DBAdmin tests passed${NC}"
else
    echo -e "${RED}‚ùå DBAdmin tests failed${NC}"
    exit 1
fi

echo ""
log "3. RUNNING NETWORK SEGMENTATION TESTS"
if ./test-network-segmentation.sh; then
    echo -e "${GREEN}‚úÖ Network segmentation tests passed${NC}"
else
    echo -e "${RED}‚ùå Network segmentation tests failed${NC}"
    exit 1
fi

echo ""
log "4. RUNNING USER PERMISSIONS TESTS"
if ./test-user-permissions.sh; then
    echo -e "${GREEN}‚úÖ User permissions tests passed${NC}"
else
    echo -e "${RED}‚ùå User permissions tests failed${NC}"
    exit 1
fi

echo ""
echo "============================================"
echo -e "${GREEN}Ìæâ ALL TESTS COMPLETED SUCCESSFULLY!${NC}"
echo "============================================"
echo ""
echo "Ì≥ä TEST SUMMARY:"
echo "‚úÖ WebAdmin has full EC2 access"
echo "‚úÖ DBAdmin has read-only access"
echo "‚úÖ Network segmentation is properly implemented"
echo "‚úÖ User permissions are correctly configured"
echo "‚úÖ All security controls are working"
echo ""
echo "ÔøΩÔøΩ SECURITY VALIDATION COMPLETE"
echo "All CAPSTONE project requirements have been verified!"
