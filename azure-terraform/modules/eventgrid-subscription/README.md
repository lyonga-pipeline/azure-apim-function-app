# Event Grid Subscription Module

This module manages Event Grid event subscriptions separately from the source topic or resource.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| Publisher/subscriber lifecycle | Subscriptions can be embedded into topic or storage modules. | Subscriptions are separate so consumers can deploy independently. |
| Destination support | Event delivery can require many destination types. | Supports webhook, Azure Function, Storage Queue, Event Hub, Hybrid Connection, Service Bus Queue, and Service Bus Topic destinations. |
| Reliability | Retry, dead-lettering, identities, and delivery headers can be missed. | Exposes retry policy, dead-letter destination, delivery identity, dead-letter identity, and delivery properties. |
| Filtering | Advanced filtering can become custom code. | Supports subject filters and advanced filters. |

## Design Intent

Use this module when a workload subscribes to events from a topic, system topic, or supported Event Grid scope. Keep the publisher resource separate from subscriber delivery configuration.

## Why This Matters

Event subscribers often change more frequently than publishers. This module lets teams add, remove, or change subscriptions without modifying the source resource lifecycle.

