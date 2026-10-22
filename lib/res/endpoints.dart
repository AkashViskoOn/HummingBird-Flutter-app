class Endpoints {
  static const String baseUrl = 'https://secureapi.myhummingbird.net';
  // static const String baseUrl = 'https://api.myhummingbird.net'; // old URL - commented
  static const String socketUrl = String.fromEnvironment(
    'SOCKET_URL',
    defaultValue: 'https://socket.myhummingbird.net:4000',
  );

  static const loginUser = '$baseUrl/user/register-number';
  static const loginOTP = '$baseUrl/user/otp-verify';
  static const getUser = '$baseUrl/user/get-single-user';
  static const updateUser = '$baseUrl/user/update-user-profile';
  static const requestChangeNumber = '$baseUrl/user/request-change-number';
  static const changeNumber = '$baseUrl/user/change-number';
  static const requestAccountDelete = '$baseUrl/user/request-account-delete';
  static const deleteAccount = '$baseUrl/user/delete-account';
  static const blockUser = '$baseUrl/user/block-user';
  static const unBlockUser = '$baseUrl/user/unblock-user';
  static const reportUser = '$baseUrl/report/report-user';
  static const fetchHummingContacts = '$baseUrl/user/get-users';
  static const addContact = '$baseUrl/contact/add-contact';
  static const fetchContacts = '$baseUrl/contact/fetch-contacts';
  static const checkContactUser = '$baseUrl/contact/check-user';
  static const fetchMessages = '$baseUrl/message/fetch-messages';
  static const sendMessage = '$baseUrl/message/send-message';
  static const deleteMessage = '$baseUrl/message/delete-message';
  static const scheduleMessage = '$baseUrl/schedule-message';
  static const updateMessage = '$baseUrl/message/update-message';
  static const createRooms = '$baseUrl/room/create-room';
  static const fetchRooms = '$baseUrl/room/fetch-rooms';
  static const deleteRoom = '$baseUrl/room/delete-room';
  static const fetchGroupInfo = '$baseUrl/room/get-group-info';
  static const updateGroup = '$baseUrl/room/update-room';
  static const addGroupMembers = '$baseUrl/room/add-users';
  static const makeAdmin = '$baseUrl/room/make-admin';
  static const removeFromAdmin = '$baseUrl/room/remove-admin';
  static const leaveGroup = '$baseUrl/room/leave-group';
  static const toggleArchive = '$baseUrl/room/toggle-archive';
  static const toggleFavorite = '$baseUrl/room/toggle-favorite';
  static const toggleMute = '$baseUrl/room/toggle-mute';
  static const markRead = '$baseUrl/room/mark-read';
  static const markUnread = '$baseUrl/room/mark-unread';
  static const saveSecretKey = '$baseUrl/user/save-secret-key';

  // Desktop device linking (DevicePairingController).
  // Only approve/reject are used from the phone: the desktop creates and claims
  // its own pairing session. create/status/claim are deliberately NOT declared
  // here so the mobile app cannot accidentally take a role in the flow that
  // belongs to the machine showing the QR.
  static const desktopPairingApprove =
      '$baseUrl/user/desktop-pairing/approve';
  static const desktopPairingReject = '$baseUrl/user/desktop-pairing/reject';

  static const linkedDevices = '$baseUrl/user/linked-devices';
  static const linkedDevicesRevoke = '$baseUrl/user/linked-devices/revoke';
  static const linkedDevicesRename = '$baseUrl/user/linked-devices/rename';
  static const linkedDevicesLogout = '$baseUrl/user/linked-devices/logout';
  static const fetchScheduledMessages =
      '$baseUrl/message/get-scheduled-messages';
  static const deleteScheduledMessages =
      '$baseUrl/message/delete-scheduled-message';

  // Phase 1 - Advanced Chat Features
  static const toggleReaction = '$baseUrl/message/toggle-reaction';
  static const pinMessage = '$baseUrl/message/pin-message';
  static const unpinMessage = '$baseUrl/message/unpin-message';
  static const starMessage = '$baseUrl/message/star-message';
  static const unstarMessage = '$baseUrl/message/unstar-message';
  static const forwardMessage = '$baseUrl/message/forward-message';
  static const messageInfo = '$baseUrl/message/message-info';
  static const searchInChat = '$baseUrl/message/search-messages';
  static const fetchPinnedMessages = '$baseUrl/message/fetch-pinned-messages';
  static const fetchStarredMessages = '$baseUrl/message/fetch-starred-messages';

  // Phase 2 - Smart Scheduling 2.0
  static const scheduleCategories = '$baseUrl/schedule/categories';
  static const saveScheduleTemplate = '$baseUrl/schedule/save-template';
  static const getScheduleTemplates = '$baseUrl/schedule/get-templates';
  static const deleteScheduleTemplate = '$baseUrl/schedule/delete-template';
  static const upcomingSchedules = '$baseUrl/schedule/upcoming';
  static const saveDraftScheduled = '$baseUrl/schedule/save-draft';
  static const getDraftScheduled = '$baseUrl/schedule/get-drafts';
  static const deleteDraftScheduled = '$baseUrl/schedule/delete-draft';
  static const markScheduleFailed = '$baseUrl/schedule/mark-failed';
  static const retryFailedSchedule = '$baseUrl/schedule/retry-failed';
  static const searchScheduledMessages = '$baseUrl/schedule/search';
  static const parseNaturalSchedule = '$baseUrl/schedule/parse';

  // Base Url for user uploaded media in chat
  static const mediaBaseUrl = 'https://secureapi.myhummingbird.net';
  // static const mediaBaseUrl = 'https://api.myhummingbird.net'; // old URL - commented

  // Phase 3 - Premium Media Experience
  static const mediaCompress = '$baseUrl/media/compress';
  static const mediaShare = '$baseUrl/media/share';
  static const mediaInfo = '$baseUrl/media/info';
  static const mediaGallery = '$baseUrl/media/gallery';
  static const mediaTrimVideo = '$baseUrl/media/trim-video';

  // Phase 4 - AI Communication Suite
  static const aiReplySuggestions = '$baseUrl/ai/reply-suggestions';
  static const aiCategorize = '$baseUrl/ai/categorize';
  static const aiSummarize = '$baseUrl/ai/summarize';
  static const aiSentiment = '$baseUrl/ai/sentiment';
  static const aiSmartSearch = '$baseUrl/ai/smart-search';
  static const aiTranslate = '$baseUrl/ai/translate';
  static const aiDetectSpam = '$baseUrl/ai/detect-spam';
  static const aiChatbot = '$baseUrl/ai/chatbot';
  static const aiGeminiMessage = '$baseUrl/generative-ai/get-ai-message';
  static const aiNotificationGroup = '$baseUrl/ai/notification-group';
  static const aiGenerateMessage = '$baseUrl/ai/generate-message';

  // Phase 5 - Calling Module
  static const callInit = '$baseUrl/call/init';
  static const callAnswer = '$baseUrl/call/answer';
  static const callEnd = '$baseUrl/call/end';
  static const callHistory = '$baseUrl/call/history';
  static const callDeleteHistory = '$baseUrl/call/delete-history';
  static const callFavorite = '$baseUrl/call/favorite';
  static const callFavorites = '$baseUrl/call/favorites';
  static const callBlock = '$baseUrl/call/block';
  static const callBlocked = '$baseUrl/call/blocked';
  static const callSpeedDial = '$baseUrl/call/speed-dial';
  static const callSaveRecording = '$baseUrl/call/save-recording';

  // Phase 9 - Humming Bird Status Module
  static const statusMyUpdate = '$baseUrl/status/my-update';
  static const statusFetchUpdates = '$baseUrl/status/fetch-updates';
  static const statusCreate = '$baseUrl/status/create';
  static const statusEdit = '$baseUrl/status/edit';
  static const statusView = '$baseUrl/status/view';
  static const statusViewers = '$baseUrl/status/viewers';
  static const statusChangeAvailability = '$baseUrl/status/change-availability';
  static const statusArchive = '$baseUrl/status/archive';
  static const statusArchivedList = '$baseUrl/status/archived';
  static const statusDelete = '$baseUrl/status/delete';
  static const statusReact = '$baseUrl/status/react';
  static const statusReactions = '$baseUrl/status/reactions';
  static const statusReply = '$baseUrl/status/reply';
  static const statusReplies = '$baseUrl/status/replies';
  static const statusMute = '$baseUrl/status/mute';
  static const statusMutedList = '$baseUrl/status/muted';
  static const statusSearch = '$baseUrl/status/search';
  static const statusAnalytics = '$baseUrl/status/analytics';
  static const statusUpload = '$baseUrl/status/upload';
  static const statusMy = '$baseUrl/status/my';
  static const statusFeed = '$baseUrl/status/feed';
  static const statusPrivacy = '$baseUrl/status/privacy';
  static const statusSavePrivacy = '$baseUrl/status/save-privacy';
  static const statusReport = '$baseUrl/status/report';
  static const statusShare = '$baseUrl/status/share';
  static const statusShares = '$baseUrl/status/shares';

  // Phase 10 - Scheduled Moments
  static const momentSchedule = '$baseUrl/moments/schedule';
  static const momentList = '$baseUrl/moments/list';
  static const momentDelete = '$baseUrl/moments/delete';
  static const momentEdit = '$baseUrl/moments/edit';
  static const momentDrafts = '$baseUrl/moments/drafts';
  static const momentSaveDraft = '$baseUrl/moments/save-draft';
  static const momentDeleteDraft = '$baseUrl/moments/delete-draft';
  static const momentCalendar = '$baseUrl/moments/calendar';
  static const momentUpload = '$baseUrl/moments/upload';
  static const momentPublish = '$baseUrl/moments/publish';
  static const momentCancel = '$baseUrl/moments/cancel';
  static const momentDuplicate = '$baseUrl/moments/duplicate';
  static const momentDetails = '$baseUrl/moments/details';
  static const momentPublished = '$baseUrl/moments/published';

  // Phase 11 - Chat Any Number
  static const checkUserByNumber = '$baseUrl/room/check-user-by-number';
  static const createPendingRoom = '$baseUrl/room/create-pending-room';
  static const attachPendingRooms = '$baseUrl/room/attach-pending-rooms';
}
