# Task Planning

## Goal
Сделать работы воспроизводимыми и проверяемыми до merge.

## Task Template
1. Objective: что меняем и зачем.
2. Scope: какие компоненты/namespace затрагиваются.
3. Preconditions: что должно быть уже готово.
4. Steps: последовательность действий.
5. Validation: как понять, что успешно.
6. Rollback: как откатить безопасно.

## Delivery Rules
- Один runbook на одну операцию.
- Изменения инфраструктуры только через Git.
- Для каждого изменения фиксировать команды проверки.

## Definition Of Done
- Все зависимости `dependsOn` в Flux выполнены.
- Нет `NotReady` в ключевых `Kustomization`/`HelmRelease`.
- Проверен внешний доступ к критичным ingress endpoint.
