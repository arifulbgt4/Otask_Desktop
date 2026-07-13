# ADR-002: Desktop execution and mobile control asymmetry

Status: Accepted

Desktop owns process, filesystem, PTY, clipboard, startup, and local model
authority. Mobile and web clients request scoped actions and never receive raw
process or filesystem authority.
