# ADR-007: Realtime signaling with WebRTC terminal transport

Status: Accepted

Supabase Realtime carries presence/signaling/state. Encrypted WebRTC
DataChannels carry interactive terminal bytes, with authenticated STUN/TURN
fallback and visible session scope/expiry.
