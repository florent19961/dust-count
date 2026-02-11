# Feature : Dashboard

## Responsabilité
Visualisations graphiques de la répartition des tâches ménagères dans un foyer.

## Structure
- data/dashboard_repository.dart — Agrégation des taskLogs (minutes/membre, cumul/jour)
- domain/dashboard_providers.dart — Providers (minutesPerMember, dailyCumulative, leaderboard)
- presentation/dashboard_screen.dart — Vue principale avec filtre + 3 sections
- presentation/widgets/ — TimeDistributionChart, CumulativeEvolutionChart, LeaderboardWidget, MemberAvatar

## Graphiques (fl_chart)
1. **Répartition du temps** : PieChart — minutes totales par membre
2. **Évolution cumulée** : LineChart — cumul jour par jour, une courbe par membre
3. **Leaderboard** : Classement par minutes, avec badges pénibilité

## Filtres
Période (semaine/mois/custom) + Catégorie + Tâche spécifique (section avancée dépliable).
DashboardFilter propre au dashboard (dashboardFilterProvider), distinct du TaskFilter de l'historique.
Partagés en termes de FilterPeriod enum uniquement.
