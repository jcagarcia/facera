# Facera

**Facera** is a ruby framework for building **multi-facet APIs** from a single semantic core.

<img src="img/facera.png" alt="Facera logo" width="200"/>

Instead of designing APIs as collections of endpoints, Facera treats an API as a **single semantic core** that can be exposed through multiple **facets**, each representing a different view of the same system.

Different consumers can interact with the same system through different facets:

- external clients
- internal services
- operator tools
- automated agents

All facets originate from the same core model and remain **consistent by design**.

---

## The Idea

Think of an API like a multi-faceted object.

It has one structure, but multiple faces. Each face reveals a different view of the same system.

```
            Facet: external
                  │
Facet: agent ── Core ── Facet: internal
                  │
            Facet: operator
```

The **core** defines the meaning of the system.

**Facets** project that meaning in ways that are appropriate for different consumers.

---

## Core Concepts

Facera is built around a small set of concepts.

### Core

The semantic definition of the system.

It defines entities, capabilities, invariants, and transitions without depending on transport protocols or consumers.

---

### Entity

A domain object within the system.

Examples include payments, users, orders, or documents.

---

### Capability

An action that can be performed in the system.

Examples include creating a resource, confirming an operation, or updating a state.

---

### Facet

A consumer-specific projection of the system.

A facet controls:

- visible entities
- exposed fields
- available capabilities
- explanation level

Different facets can present the same system differently while remaining logically consistent.

---

## Why Facera

Modern systems expose APIs to many different consumers.

This often leads to duplicated APIs and inconsistent representations.

Facera solves this by allowing developers to define the system **once** and expose multiple **facets** derived from the same semantic core.

---

## Status

Facera is an experimental project exploring a new approach to API design based on **facet-oriented systems**.

---

## Vision

* One system
* Many facets
* Zero duplication

---

## License

MIT License
