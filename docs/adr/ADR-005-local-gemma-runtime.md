# ADR-005: Gemma 4 E4B with embedded llama.cpp

Status: Accepted

Gemma 4 E4B is the only v1 model. The runtime is bundled or tightly
controlled through a pinned llama.cpp-compatible build. Ollama, hosted model
fallback, model routing, and additional models are excluded.
