/// Hardcoded French strings for the app.
///
/// Replaces the l10n system (AppLocalizations) with static constants
/// and methods for parameterized strings.
abstract final class S {
  // App
  static const appName = 'DustCount';

  // Onboarding
  static const onboardingWelcomeTitle = 'Bienvenue sur DustCount';
  static const onboardingWelcomeDescription =
      'Suivez les tâches ménagères ensemble, équitablement et en toute transparence';
  static const onboardingConceptTitle =
      'Comme Tricount, mais pour les tâches ménagères';
  static const onboardingConceptDescription =
      'Chaque membre du foyer enregistre ses tâches. Voyez qui fait quoi, suivez le temps passé et gardez l\'équilibre.';
  static const onboardingGetStartedTitle = 'Commencer';
  static const onboardingGetStartedDescription =
      'Créez ou rejoignez un foyer et commencez à suivre les tâches avec votre famille ou vos colocataires';
  static const next = 'Suivant';
  static const skip = 'Passer';
  static const getStarted = 'Commencer';

  // Auth
  static const login = 'Se connecter';
  static const register = "S'inscrire";
  static const email = 'Email';
  static const password = 'Mot de passe';
  static const confirmPassword = 'Confirmer le mot de passe';
  static const displayName = "Nom d'affichage";
  static const forgotPassword = 'Mot de passe oublié ?';
  static const resetPassword = 'Réinitialiser le mot de passe';
  static const sendResetLink = 'Envoyer le lien de réinitialisation';
  static const backToLogin = 'Retour à la connexion';
  static const noAccount = "Vous n'avez pas de compte ?";
  static const haveAccount = 'Vous avez déjà un compte ?';
  static const emailRequired = "L'email est requis";
  static const emailInvalid = 'Veuillez entrer un email valide';
  static const passwordRequired = 'Le mot de passe est requis';
  static const passwordTooShort =
      'Le mot de passe doit contenir au moins 6 caractères';
  static const passwordsDoNotMatch =
      'Les mots de passe ne correspondent pas';
  static const displayNameRequired = "Le nom d'affichage est requis";
  static const loginSuccess = 'Connexion réussie';
  static const registerSuccess = 'Compte créé avec succès';
  static const resetEmailSent = 'Email de réinitialisation envoyé';
  static const loginSubtitle = 'Connectez-vous à votre compte';
  static const dontHaveAccount = "Vous n'avez pas de compte ?";
  static const signUp = "S'inscrire";
  static const forgotPasswordDescription =
      'Entrez votre adresse email et nous vous enverrons un lien pour réinitialiser votre mot de passe.';
  static const resetEmailDescription =
      'Si un compte existe avec cet email, vous recevrez bientôt un lien de réinitialisation.';
  static const resetEmailSpamHint =
      'Pensez à vérifier votre dossier spam ou courrier indésirable.';
  static const createAccount = 'Créer un compte';
  static const registrationDescription =
      'Créez un nouveau compte pour commencer';
  static const alreadyHaveAccount = 'Vous avez déjà un compte ?';
  static const signIn = 'Se connecter';
  static const registerSubtitle = 'Créer un nouveau compte';
  static const passwordHint = 'Au moins 6 caractères';
  static const confirmPasswordRequired =
      'Veuillez confirmer votre mot de passe';

  // Household
  static const household = 'Foyer';
  static const households = 'Foyers';
  static const createHousehold = 'Créer un foyer';
  static const joinHousehold = 'Rejoindre un foyer';
  static const leaveHousehold = 'Quitter le foyer';
  static const inviteMembers = 'Inviter des membres';
  static const householdName = 'Nom du foyer';
  static const householdNameRequired = 'Le nom du foyer est requis';
  static const inviteCode = "Code d'invitation";
  static const inviteCodeRequired = "Le code d'invitation est requis";
  static const inviteCodeInvalid = "Code d'invitation invalide";
  static const members = 'Membres';
  static const shareInviteLink = "Partager le lien d'invitation";
  static const copyInviteCode = "Copier le code d'invitation";
  static const inviteCodeCopied =
      "Code d'invitation copié dans le presse-papiers";
  static const householdCreated = 'Foyer créé avec succès';
  static const householdJoined = 'Foyer rejoint avec succès';
  static const leaveHouseholdConfirm =
      'Êtes-vous sûr de vouloir quitter ce foyer ?';
  static const householdLeft = 'Foyer quitté avec succès';
  static const selectHousehold = 'Sélectionner un foyer';
  static const noHouseholdsYet = 'Aucun foyer pour le moment';
  static const joinOrCreate =
      'Rejoignez ou créez un foyer pour commencer';
  static const enterInviteCode = "Entrer le code d'invitation";
  static const yourHouseholds = 'Vos foyers';
  static const errorLoadingHouseholds =
      'Erreur lors du chargement des foyers';
  static const householdMembers = 'Membres du foyer';
  static const inviteLinkCopied =
      "Lien d'invitation copié dans le presse-papiers";
  static const errorCreatingHousehold =
      'Erreur lors de la création du foyer';
  static const createNewHousehold = 'Créer un nouveau foyer';
  static const createHouseholdDescription =
      'Créez un foyer et invitez votre famille ou vos colocataires';
  static const householdNameHint = 'ex: Maison Famille Dupont';
  static const householdNameTooShort = 'Le nom du foyer est trop court';
  static const householdNameTooLong = 'Le nom du foyer est trop long';
  static const create = 'Créer';
  static const householdNotFound = 'Foyer non trouvé';
  static const errorLoadingHousehold =
      'Erreur lors du chargement du foyer';
  static const myHouseholds = 'Mes foyers';
  static const noHouseholds = 'Aucun foyer pour le moment';
  static const noHouseholdsDescription =
      'Créez ou rejoignez un foyer pour commencer à suivre les tâches ensemble';
  static const createYourFirstHousehold = 'Créez votre premier foyer';
  static const orJoinExisting = 'ou rejoignez-en un existant';
  static const householdSettings = 'Paramètres du foyer';
  static const inviteLink = "Lien d'invitation";
  static const copy = 'Copier';
  static const share = 'Partager';
  static const predefinedTasks = 'Tâches prédéfinies';
  static const predefinedTasksDescription =
      'Ces tâches sont disponibles pour tous les membres du foyer';
  static const leaveHouseholdConfirmation =
      'Êtes-vous sûr de vouloir quitter ce foyer ? Cette action est irréversible.';
  static const leave = 'Quitter';
  static const errorLeavingHousehold =
      'Erreur lors de la sortie du foyer';
  static const errorJoiningHousehold =
      "Erreur lors de l'adhésion au foyer";
  static const joinExistingHousehold = 'Rejoindre un foyer existant';
  static const joinHouseholdDescription =
      "Entrez le code d'invitation de votre famille ou colocataire";
  static const inviteCodeHint = 'ex: ABC123';
  static const inviteCodeHelper =
      "Demandez le code d'invitation à l'administrateur du foyer";
  static const join = 'Rejoindre';
  static const welcomeBackMemberTitle = 'Bon retour !';
  static const welcomeBackMemberKeep = 'Garder ce nom';
  static const welcomeBackMemberChange = 'Choisir un autre nom';
  static const nameConflictTitle = 'Nom déjà utilisé';
  static const nameConflictMessage =
      'Ce nom est déjà utilisé par un autre membre du foyer. Choisissez un autre nom pour ce foyer.';
  static const newDisplayNameLabel = 'Nouveau nom pour ce foyer';
  static const newDisplayNameRequired = 'Veuillez entrer un nom';
  static const nameStillConflict = 'Ce nom est aussi déjà pris';

  static String welcomeBackMemberMessage(String previousName) =>
      'Vous étiez connu(e) comme «\u202F$previousName\u202F» dans ce foyer. Souhaitez-vous garder ce nom ?';

  // Tasks
  static const tasks = 'Tâches';
  static const task = 'Tâche';
  static const addTask = 'Ajouter une tâche';
  static const logTask = 'Enregistrer la tâche';
  static const taskName = 'Nom de la tâche';
  static const taskNameRequired = 'Le nom de la tâche est requis';
  static const category = 'Catégorie';
  static const categoryRequired = 'La catégorie est requise';
  static const difficulty = 'Difficulté';
  static const difficultyRequired = 'La difficulté est requise';
  static const duration = 'Durée';
  static const minutes = 'minutes';
  static const minutesShort = 'min';
  static const durationRequired = 'La durée est requise';
  static const date = 'Date';
  static const comment = 'Commentaire';
  static const taskHistory = 'Historique des tâches';
  static const filter = 'Filtrer';
  static const filterByCategory = 'Filtrer par catégorie';
  static const filterByMember = 'Filtrer par membre';
  static const filterByTask = 'Filtrer par tâche';
  static const allTasks = 'Toutes les tâches';
  static const resetFilters = 'Réinitialiser';
  static const advancedFilters = 'Filtres avancés';
  static const filterByDifficulty = 'Filtrer par pénibilité';
  static const clearFilters = 'Effacer les filtres';
  static const taskLogged = 'Tâche enregistrée avec succès';
  static const taskDeleted = 'Tâche supprimée avec succès';
  static const deleteTaskConfirm =
      'Êtes-vous sûr de vouloir supprimer cette tâche ?';

  // Categories
  static const categoryCuisine = 'Cuisine';
  static const categoryMenage = 'Ménage';
  static const categoryLinge = 'Linge';
  static const categoryCourses = 'Courses & repas';
  static const categoryDivers = 'Divers';
  static const categoryArchivees = 'Archivées';
  static const selectTask = 'Sélectionner une tâche';
  static const favoriteTasks = 'Tâches favorites';


  // Predefined task names
  static const taskVacuum = 'Aspirateur';
  static const taskMopFloor = 'Serpillère';
  static const taskDustSurfaces = 'Dépoussiérer';
  static const taskCleanWindows = 'Vitres';
  static const taskCleanToilet = 'Nettoyer toilettes';
  static const taskCleanBathroom = 'Nettoyer salle de bain';
  static const taskTakeOutTrash = 'Sortir les poubelles';
  static const taskDoDishes = 'Faire la vaisselle';
  static const taskDishwasher = 'Vider/remplir lave-vaisselle';
  static const taskCleanCountertops = 'Nettoyer plan de travail';
  static const taskCleanOvenMicrowave = 'Nettoyer four/micro-ondes';
  static const taskCleanFridge = 'Nettoyer frigo';
  static const taskDoLaundry = 'Lancer machine à laver';
  static const taskHangLaundry = 'Étendre le linge';
  static const taskFoldLaundry = 'Plier et ranger le linge';
  static const taskGroceryShopping = 'Faire les courses';
  static const taskCookMeal = 'Cuisiner';
  static const taskWaterPlants = 'Arroser les plantes';
  static const taskDIYRepairs = 'Bricolage/réparations';
  static const taskAdminTasks = 'Gestion administratif';
  static const taskVacationPlanning = 'Préparation vacances';

  // Predefined task management
  static const managePredefinedTasks = 'Gérer les tâches prédéfinies';
  static const addPredefinedTask = 'Ajouter une tâche prédéfinie';
  static const deletePredefinedTask = 'Supprimer la tâche prédéfinie';
  static const taskNameFrLabel = 'Nom de la tâche';
  static const defaultDurationLabel = 'Durée par défaut';
  static const defaultDifficultyLabel = 'Difficulté par défaut';
  static const deleteTaskWarningTitle = 'Supprimer la tâche prédéfinie ?';
  static const noPredefinedTasks = 'Aucune tâche prédéfinie';
  static const taskAddedToPredefined = 'Tâche ajoutée aux tâches prédéfinies';
  static const taskRemovedFromPredefined =
      'Tâche supprimée des tâches prédéfinies';

  static const editPredefinedTask = 'Modifier la tâche';
  static const taskUpdatedInPredefined = 'Tâche mise à jour';
  static const quickTask = 'Tâche favorite';

  // Quick tasks configuration
  static const quickTasksConfig = 'Mes tâches favorites';
  static const quickTasksDescription =
      'Choisissez et ordonnez les tâches affichées en accès rapide';
  static const maxQuickTasksReached =
      'Maximum de 12 tâches favorites atteint';

  // Dashboard
  static const dashboard = 'Tableau de bord';
  static const distribution = 'Répartition';
  static const evolution = 'Évolution';
  static const leaderboard = 'Classement';
  static const thisWeek = 'Cette semaine';
  static const thisMonth = 'Ce mois-ci';
  static const customPeriod = 'Période personnalisée';
  static const totalMinutes = 'Minutes totales';
  static const tasksCount = 'Nombre de tâches';
  static const byCategory = 'Par catégorie';
  static const byMember = 'Par membre';
  static const byDifficulty = 'Par difficulté';
  static const selectDateRange = 'Sélectionner la période';
  static const startDate = 'Date de début';
  static const endDate = 'Date de fin';
  static const timeDistribution = 'Répartition du temps';
  static const cumulativeEvolution = 'Évolution cumulative';
  static const period = 'Période';
  static const custom = 'Personnalisée';
  static const noDataAvailable = 'Aucune donnée disponible';
  static const errorLoadingDashboard =
      'Erreur lors du chargement du tableau de bord';
  static const noDataForPeriod =
      'Aucune donnée disponible pour cette période';
  static const taskDetail = 'Détail de la tâche';
  static const taskDetails = 'Détails de la tâche';
  static const performedBy = 'Effectuée par';

  // Profile / Settings
  static const profile = 'Profil';
  static const settings = 'Paramètres';
  static const editProfile = 'Modifier le profil';
  static const language = 'Langue';
  static const logout = 'Se déconnecter';
  static const logoutConfirm =
      'Êtes-vous sûr de vouloir vous déconnecter ?';
  static const profileUpdated = 'Profil mis à jour avec succès';

  // Members
  static const unknownMember = 'Inconnu';

  // Common
  static const save = 'Enregistrer';
  static const cancel = 'Annuler';
  static const delete = 'Supprimer';
  static const confirm = 'Confirmer';
  static const error = 'Erreur';
  static const success = 'Succès';
  static const loading = 'Chargement...';
  static const noData = 'Aucune donnée disponible';
  static const noTasks = 'Aucune tâche pour le moment';
  static const noMembers = 'Aucun membre pour le moment';
  static const retry = 'Réessayer';
  static const ok = 'OK';
  static const yes = 'Oui';
  static const no = 'Non';
  static const close = 'Fermer';
  static const search = 'Rechercher';
  static const all = 'Tout';
  static const today = "Aujourd'hui";
  static const yesterday = 'Hier';
  static const errorOccurred =
      "Une erreur s'est produite. Veuillez réessayer.";
  static const networkError =
      'Erreur réseau. Veuillez vérifier votre connexion.';
  static const done = 'Terminé';
  static const pleaseSelectTask = 'Veuillez sélectionner une tâche';
  static const pleaseSelectCategory =
      'Veuillez sélectionner une catégorie';
  static const taskAddedSuccess = 'Tâche ajoutée avec succès';
  static const pleaseEnterTaskName =
      'Veuillez entrer un nom de tâche';
  static const pleaseEnterValidDuration =
      'Veuillez entrer une durée valide';
  static const errorLoadingTasks =
      'Erreur lors du chargement des tâches';
  static const noTasksYet = 'Aucune tâche pour le moment';
  static const addFirstTask =
      'Ajoutez votre première tâche pour commencer !';
  static const filterThisWeek = 'Semaine';
  static const filterThisMonth = 'Mois';
  static const filterCustom = 'Période';
  static const selectPredefinedTask =
      'Sélectionnez une tâche prédéfinie';
  static const taskHistoryPlaceholder =
      "L'historique des tâches sera affiché ici";
  static const dashboardPlaceholder =
      'Le tableau de bord sera affiché ici';
  static const addTaskPlaceholder =
      "Le formulaire d'ajout de tâche sera affiché ici";
  static const history = 'Historique';
  static const add = 'Ajouter';
  static const deleteTask = 'Supprimer la tâche';
  static const deleteTaskConfirmation =
      'Êtes-vous sûr de vouloir supprimer cette tâche ? Cette action est irréversible.';
  static const taskDeletedSuccess = 'Tâche supprimée avec succès';

  // Timer
  static const startTimer = 'Chronométrer';
  static const timerRunning = 'Chronomètre en cours';
  static const pause = 'Pause';
  static const resume = 'Reprendre';
  static const stop = 'Arrêter';
  static const timerConfirmStop = 'Arrêter le chronomètre ?';
  static const timerConfirmQuit = 'Quitter le chronomètre ?';
  static const timerConfirmQuitMessage =
      'Le temps chronométré sera perdu.';

  // Personal task
  static const personalTask = 'Tâche personnelle';
  static const personalTaskDescription =
      'Exclue des statistiques du foyer';
  static const personalTaskBadge = 'Perso';
  static const filterAll = 'Toutes';
  static const filterHousehold = 'Foyer';
  static const filterPersonal = 'Perso';

  // Edit task
  static const editTask = 'Modifier la tâche';
  static const taskUpdatedSuccess = 'Tâche modifiée avec succès';
  static const saveChanges = 'Enregistrer les modifications';

  // Rename household / display name
  static const editHouseholdName = 'Modifier le nom du foyer';
  static const householdNameUpdated = 'Nom du foyer mis à jour';
  static const errorUpdatingHouseholdName =
      'Erreur lors de la mise à jour du nom du foyer';
  static const editDisplayName = "Modifier le nom d'affichage";
  static const displayNameUpdated = "Nom d'affichage mis à jour";
  static const errorUpdatingDisplayName =
      "Erreur lors de la mise à jour du nom d'affichage";

  // Parameterized strings

  static String memberCount(int count) {
    if (count == 0) return 'Aucun membre';
    if (count == 1) return '1 membre';
    return '$count membres';
  }

  static String tasksCompleted(int count) {
    if (count == 0) return 'Aucune tâche';
    if (count == 1) return '1 tâche';
    return '$count tâches';
  }

  static String minutesLogged(int minutes) => '$minutes min';

  static String minutesCount(int count) => '$count minutes';

  static String tasksAvailable(int count) => '$count tâches disponibles';

  static String andMore(int count) => 'et $count de plus...';

  static String welcomeBack(String name) => 'Bon retour, $name !';

  static String lastUpdated(String time) =>
      'Dernière mise à jour : $time';

  static String dashboardForHousehold(String householdName) =>
      'Tableau de bord pour $householdName';

  static String deleteTaskWarningMessage(String name, int count) =>
      'La tâche "$name" a $count entrée${count > 1 ? 's' : ''} dans l\'historique. Elles seront déplacées dans la catégorie "Archivées".';

  static String deleteTaskNoLogsMessage(String name) =>
      'Supprimer la tâche "$name" ? Cette action est irréversible.';

  static String quickTaskCount(int current, int max) =>
      '$current / $max sélectionnées';

  // Custom categories
  static const addCategory = 'Ajouter une catégorie';
  static const categoryNameLabel = 'Nom de la catégorie';
  static const categoryNameRequired = 'Le nom est requis';
  static const chooseIcon = 'Choisir une icône';
  static const chooseColor = 'Choisir une couleur';
  static const categoryAdded = 'Catégorie ajoutée';
  static const categoryChanged = 'Catégorie modifiée';
  static const maxCategoriesReached =
      'Maximum de 9 catégories atteint';
  static const deleteCategoryTitle = 'Supprimer la catégorie ?';
  static const deleteCategoryMessage =
      'Cette catégorie vide sera définitivement supprimée.';
  static const categoryDeleted = 'Catégorie supprimée';
  static const addTaskToCategory = 'Ajouter une tâche';
  static const dropToDelete = 'Déposer pour supprimer';

  static String taskAddedError(String error) =>
      "Erreur lors de l'ajout de la tâche : $error";

  static String taskDeletedError(String error) =>
      'Erreur lors de la suppression de la tâche : $error';

  static String taskUpdatedError(String error) =>
      'Erreur lors de la modification : $error';

  static String timerConfirmStopMessage(int minutes) =>
      'Le temps enregistré sera de $minutes minute${minutes > 1 ? 's' : ''}.';

  static String timerResult(int minutes) =>
      'Temps chronométré : $minutes min';

  static String nameConflictInHousehold(String householdName) =>
      'Ce nom est déjà utilisé par un membre du foyer "$householdName"';

  static String createdAt(String date) => 'Créée le $date';

  // Create household stepper
  static const setupTasks = 'Personnaliser les tâches';
  static const setupTasksDescription =
      'Ajoutez, modifiez ou supprimez des tâches selon vos besoins';
  static const householdNameStep = 'Nom du foyer';
  static const skipStep = 'Passer';
  static const createHouseholdAction = 'Créer le foyer';
  static const nextStep = 'Suivant';
  static String taskCount(int n) => '$n tâche${n > 1 ? 's' : ''}';

  // Date formatting helpers (replace intl DateFormat)

  /// "9 février 2026" — replaces DateFormat.yMMMMd('fr')
  static String formatDateLong(DateTime d) {
    const months = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  /// "14:30" — replaces DateFormat.Hm()
  static String formatTime(DateTime d) {
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  /// "09/02" — replaces DateFormat('dd/MM')
  static String formatDateShort(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
  }

  /// Format minutes as "Xh Ym", "Xh", or "Ym"
  static String formatMinutes(int minutes) {
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      if (remainingMinutes > 0) {
        return '${hours}h ${remainingMinutes}m';
      }
      return '${hours}h';
    }
    return '${minutes}m';
  }

  // Category breakdown chart
  static const categoryBreakdown = 'Répartition par catégorie';
  static const viewMinutes = 'Minutes';
  static const viewTaskCount = 'Nombre';

  // Repository errors — User
  static String errorCreateUser(String e) =>
      'Échec de création utilisateur : $e';
  static String errorGetUser(String e) =>
      'Échec de récupération utilisateur : $e';
  static String errorUpdateUser(String e) =>
      'Échec de mise à jour utilisateur : $e';
  static String errorWatchUser(String e) =>
      "Échec d'écoute utilisateur : $e";
  static String errorAddHouseholdToUser(String e) =>
      "Échec d'ajout du foyer à l'utilisateur : $e";
  static String errorRemoveHouseholdFromUser(String e) =>
      "Échec de retrait du foyer de l'utilisateur : $e";
  static String errorUpdateUserDisplayName(String e) =>
      "Échec de mise à jour du nom d'affichage : $e";
  static String errorUpdateLocale(String e) =>
      'Échec de mise à jour de la langue : $e';

  // Repository errors — Task
  static String errorAddTaskLog(String e) =>
      "Échec d'ajout de la tâche : $e";
  static String errorUpdateTaskLog(String e) =>
      'Échec de mise à jour de la tâche : $e';
  static String errorDeleteTaskLog(String e) =>
      'Échec de suppression de la tâche : $e';
  static String errorWatchTaskLogs(String e) =>
      "Échec d'écoute des tâches : $e";
  static String errorGetTaskLogs(String e) =>
      'Échec de récupération des tâches : $e';
  static String errorCountTaskLogs(String e) =>
      'Échec de comptage des tâches : $e';
  static String errorCheckUserTasks(String e) =>
      'Échec de vérification des tâches : $e';
  static String errorRenameTaskLogs(String e) =>
      'Échec de renommage des tâches : $e';
  static String errorUpdatePerformedByName(String e) =>
      "Échec de mise à jour du nom de l'exécutant : $e";
  static String errorMigrateTaskCategory(String e) =>
      'Échec de migration de catégorie : $e';

  // Repository errors — Household
  static String errorCreateHousehold(String e) =>
      'Échec de création du foyer : $e';
  static String errorGetHousehold(String e) =>
      'Échec de récupération du foyer : $e';
  static String errorWatchHousehold(String e) =>
      "Échec d'écoute du foyer : $e";
  static String errorWatchUserHouseholds(String e) =>
      "Échec d'écoute des foyers : $e";
  static String errorFindByInviteCode(String e) =>
      "Échec de recherche par code d'invitation : $e";
  static String errorAddMember(String e) =>
      "Échec d'ajout du membre : $e";
  static String errorRemoveMember(String e) =>
      'Échec de retrait du membre : $e';
  static String errorUpdatePredefinedTasks(String e) =>
      'Échec de mise à jour des tâches prédéfinies : $e';
  static String errorUpdateHouseholdName(String e) =>
      'Échec de mise à jour du nom du foyer : $e';
  static String errorUpdateMemberName(String e) =>
      'Échec de mise à jour du nom du membre : $e';
  static const cannotDeleteHouseholdWithMembers =
      'Impossible de supprimer un foyer avec des membres';
  static String errorDeleteHousehold(String e) =>
      'Échec de suppression du foyer : $e';
  static String errorAddPredefinedTask(String e) =>
      "Échec d'ajout de la tâche prédéfinie : $e";
  static String errorRemovePredefinedTask(String e) =>
      'Échec de suppression de la tâche prédéfinie : $e';
  static String errorUpdatePredefinedTask(String e) =>
      'Échec de mise à jour de la tâche prédéfinie : $e';
  static String errorUpdateQuickTaskIds(String e) =>
      'Échec de mise à jour des tâches favorites : $e';
  static String errorRemoveCustomCategory(String e) =>
      'Échec de suppression de la catégorie : $e';
  static String errorAddCustomCategory(String e) =>
      "Échec d'ajout de la catégorie : $e";
}
