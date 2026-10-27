# TECH_STACK.md

# PureScan AI Technology Stack

## Overview

This document defines the official technology stack for PureScan AI.

---

# Frontend Stack

## Mobile Framework

### Flutter
Purpose: Android & iOS Applications
Advantages: Single codebase, Native performance, Fast development

### State Management
Riverpod

### Local Storage
Hive

## Web Application Stack

### React & Vite
Purpose: Web Dashboard / Portal
Advantages: Lightning-fast HMR, component-based architecture
Styling: Tailwind CSS

## Marketing Website

### Vanilla HTML / CSS / JS
Purpose: High-performance, lightweight landing page and portfolio.
Advantages: Zero dependencies, instant loading, complete animation control.

---

# Camera & Scanning Stack

## OCR Engine
Google ML Kit

## Barcode Scanner
Mobile Scanner

---

# Backend Stack

## Language
Go (1.24+)
Purpose: API Services, Business Logic, Trust Score Engine

## Framework
Gin

---

# API Design
REST API via JSON. Authentication via JWT.

---

# Database Stack

## Primary Database
PostgreSQL (via Supabase)

## Cache Layer
Redis

## Search Infrastructure
Meilisearch

## Storage Infrastructure
Cloudflare R2

---

# Authentication
Supabase Auth (Google, Email, OTP)

---

# AI Stack

## Primary AI Provider
Advanced Edge AI / LLM Provider

Purpose:
- Ingredient Explanation
- Product Summary
- Health Insights

---

# Analytics
PostHog

---

# Infrastructure & CI/CD
- Hosting: Vercel (Web/Portfolio), AWS (Backend/Database)
- CI/CD: GitHub Actions

---

Status: Approved
Version: 2.0
Project: PureScan AI