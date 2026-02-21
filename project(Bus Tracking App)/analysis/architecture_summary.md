# Architecture Summary

-> rule 6 is executed

## Project Overview

This project is a comprehensive Bus Tracking System designed for colleges. It provides real-time tracking, SOS alerts, and administrative controls for buses, routes, students, and staff.

## Tech Stack

- **Backend**: Node.js, Express, TypeScript, MongoDB, Redis, Socket.IO.
- **Web Frontend**: React 19, Vite, Redux Toolkit, Tailwind CSS v4.
- **Mobile App**: Flutter, Riverpod, GoRouter, Google Maps, Socket.IO Client.

## Repository Structure

- `server/`: Backend API and Real-time logic.
- `client/`: Web dashboard for College and Super Admins.
- `CollegeBusTrackingFlutterApp/`: Mobile app for all user roles.

## Core Data Flow

1. **Drivers** send location updates via Mobile App (Socket.IO).
2. **Server** receives updates, broadcasts them to relevant rooms (College/Global), and buffers them for periodic DB storage (Write-behind pattern).
3. **Students/Admins** receive live updates via Socket.IO and visualize them on maps.
4. **SOS Alerts** are broadcast to coordinators in real-time.
