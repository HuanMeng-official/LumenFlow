// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'LumenFlow';

  @override
  String get appSubtitle => 'Chatea con tu IA';

  @override
  String get chat => 'Chat';

  @override
  String get settings => 'Ajustes';

  @override
  String get about => 'Acerca de';

  @override
  String get conversations => 'Conversaciones';

  @override
  String get newConversation => 'Nueva conversación';

  @override
  String get noConversations => 'Sin conversaciones aún';

  @override
  String get createNewConversation => 'Crear nueva conversación';

  @override
  String get aiAssistant => 'Asistente IA';

  @override
  String get startChatting => '¡Empieza a chatear con la IA!';

  @override
  String get pleaseConfigureAPI => 'Configura los ajustes de la API para empezar a chatear';

  @override
  String get settingsButton => 'Ajustes';

  @override
  String get needConfiguration => 'Configuración requerida';

  @override
  String get configureAPIPrompt => 'Configura el punto de acceso y la clave API en los ajustes';

  @override
  String get cancel => 'Cancelar';

  @override
  String get confirm => 'Confirmar';

  @override
  String get save => 'Guardar';

  @override
  String get delete => 'Eliminar';

  @override
  String get edit => 'Editar';

  @override
  String get ok => 'Aceptar';

  @override
  String get goToSettings => 'Ir a Ajustes';

  @override
  String get clearConversation => 'Limpiar conversación actual';

  @override
  String get clearConversationConfirm => '¿Estás seguro de que quieres borrar todos los mensajes de la conversación actual?';

  @override
  String get deleteConversation => 'Eliminar conversación';

  @override
  String deleteConversationConfirm(String title) {
    return '¿Estás seguro de que quieres eliminar la conversación \"$title\"? Esta acción no se puede deshacer.';
  }

  @override
  String get editConversationTitle => 'Editar título de la conversación';

  @override
  String get enterConversationTitle => 'Introduce el título de la conversación';

  @override
  String get saveSuccess => 'Guardado con éxito';

  @override
  String get settingsSaved => 'Los ajustes han sido guardados';

  @override
  String get saveFailed => 'Error al guardar';

  @override
  String saveError(String error) {
    return 'Error al guardar los ajustes: $error';
  }

  @override
  String get resetSettings => 'Restablecer ajustes';

  @override
  String get resetSettingsConfirm => '¿Estás seguro de que quieres restaurar los ajustes por defecto? Esto borrará todas las configuraciones actuales.';

  @override
  String get exportSettings => 'Exportar ajustes';

  @override
  String get exportSuccess => 'Exportación exitosa';

  @override
  String exportLocation(String location, String path) {
    return 'Los ajustes se han exportado con éxito a $location:\n$path';
  }

  @override
  String get exportFailed => 'Error al exportar';

  @override
  String exportError(String error) {
    return 'Error al exportar los ajustes: $error\n\nAsegúrate de que la aplicación tenga permisos de almacenamiento y comprueba el espacio disponible.';
  }

  @override
  String get importSettings => 'Importar ajustes';

  @override
  String get importSettingsConfirm => 'Esto sobrescribirá los ajustes actuales. ¿Estás seguro de que quieres importar?';

  @override
  String get importSuccess => 'Importación exitosa';

  @override
  String get settingsImported => 'Los ajustes se han importado con éxito.';

  @override
  String get importFailed => 'Error al importar';

  @override
  String importError(String error) {
    return 'Error al importar los ajustes: $error';
  }

  @override
  String get error => 'Error';

  @override
  String get responseInterrupted => 'Respuesta interrumpida, la aplicación podría haber salido inesperadamente';

  @override
  String get yesterday => 'Ayer';

  @override
  String daysAgo(int days) {
    return 'Hace $days días';
  }

  @override
  String get editTitle => 'Editar título';

  @override
  String get deleteConversation2 => 'Eliminar conversación';

  @override
  String get userInfo => 'Información de usuario';

  @override
  String get userProfile => 'Perfil de usuario';

  @override
  String get userProfileDesc => 'Establecer avatar y nombre de usuario';

  @override
  String get basicSettings => 'Ajustes básicos';

  @override
  String get apiType => 'Tipo de API';

  @override
  String get openaiApi => 'OpenAI API';

  @override
  String get geminiApi => 'Gemini API';

  @override
  String get deepseekApi => 'DeepSeek API';

  @override
  String get claudeApi => 'Claude API';

  @override
  String get siliconflowApi => 'SiliconFlow API';

  @override
  String get minimaxApi => 'MiniMax API';

  @override
  String get zhipuApi => 'ZhipuAI API';

  @override
  String get kimiApi => 'Kimi API';

  @override
  String get lmsApi => 'LM-Studio API';

  @override
  String get grokApi => 'Grok API';

  @override
  String get openrouterApi => 'OpenRouter API';

  @override
  String get otherApi => 'Otra API';

  @override
  String get mimoApi => 'XiaoMi MiMo API';

  @override
  String get apiTypeDesc => 'Seleccionar proveedor de servicios de IA';

  @override
  String get apiEndpoint => 'Punto de acceso API';

  @override
  String get apiEndpointPlaceholder => 'Introduce la URL del punto de acceso API';

  @override
  String get apiEndpointDesc => 'ej: https://api.openai.com/v1';

  @override
  String get apiKey => 'Clave API';

  @override
  String get apiKeyPlaceholder => 'Clave API';

  @override
  String get apiKeyDesc => 'Clave de autenticación obtenida del proveedor de servicios de IA';

  @override
  String get modelSettings => 'Ajustes del modelo';

  @override
  String get model => 'Modelo';

  @override
  String get modelPlaceholder => 'Introduce el nombre del modelo';

  @override
  String get modelDesc => 'ej: gpt-4o, deepseek-chat';

  @override
  String get maxTokens => 'Tokens máximos';

  @override
  String get maxTokensPlaceholder => 'Introduce los tokens máximos';

  @override
  String get maxTokensDesc => 'Limita la longitud de una sola respuesta, recomendado 6000-10000';

  @override
  String get systemPrompt => 'Mensaje del sistema';

  @override
  String get systemPromptPlaceholder => 'Introduce el mensaje del sistema';

  @override
  String get systemPromptDesc => 'ej: Responde siempre en español';

  @override
  String get temperature => 'Temperatura';

  @override
  String get temperatureDesc => 'Controla la aleatoriedad de la respuesta, 0.0-2.0, valores altos significan respuestas más creativas';

  @override
  String get historyConversation => 'Historial de conversación';

  @override
  String get enableHistory => 'Habilitar historial';

  @override
  String get enableHistoryDesc => 'Cuando está activo, la IA recordará el contexto de la conversación anterior para dar respuestas coherentes';

  @override
  String get historyRounds => 'Rondas de historial';

  @override
  String get historyRoundsPlaceholder => 'Introduce el número de rondas';

  @override
  String get historyRoundsDesc => 'Número de rondas que la IA recuerda, recomendado 5-20. Demasiadas pueden exceder el límite de tokens';

  @override
  String get conversationTitle => 'Título de la conversación';

  @override
  String get autoGenerateTitle => 'Generar título automáticamente';

  @override
  String get autoGenerateTitleDesc => 'Tras varias rondas, la IA generará automáticamente un título basado en el contenido';

  @override
  String get generateTiming => 'Momento de generación';

  @override
  String get generateTimingDesc => 'Establece cuántas rondas de conversación deben pasar antes de generar el título';

  @override
  String get rounds => 'rondas';

  @override
  String get appearance => 'Apariencia de la APP';

  @override
  String get followSystem => 'Seguir sistema';

  @override
  String get followSystemDesc => 'Seguir automáticamente el modo de color del sistema';

  @override
  String get appColor => 'Color de la aplicación';

  @override
  String get lightMode => 'Modo claro';

  @override
  String get darkMode => 'Modo oscuro';

  @override
  String followSystemSetting(String mode) {
    return 'Siguiendo sistema ($mode)';
  }

  @override
  String get selectColorMode => 'Seleccionar modo de color';

  @override
  String get others => 'Otros';

  @override
  String get resetToDefault => 'Restablecer valores por defecto';

  @override
  String get commonApiEndpoints => 'Puntos de acceso comunes';

  @override
  String get commonApiEndpointsContent => 'OpenAI: https://api.openai.com/v1\n\nDeepSeek: https://api.deepseek.com\n\nAlibaba Cloud: https://dashscope.aliyuncs.com/api/v1\n\nRellena la dirección correspondiente según el proveedor que utilices.';

  @override
  String get commonModels => 'Modelos comunes';

  @override
  String get commonModelsContent => 'OpenAI:\n• gpt-4o\n\nDeepSeek:\n• deepseek-chat\n• deepseek-reasoner\n\nSelecciona el modelo correspondiente según tu punto de acceso API.';

  @override
  String get appInfo => 'Información de la aplicación';

  @override
  String get version => 'Versión';

  @override
  String get buildDate => 'Fecha de compilación';

  @override
  String get developer => 'Desarrollador';

  @override
  String get features => 'Funcionalidades';

  @override
  String get intelligentConversation => 'Conversación inteligente';

  @override
  String get intelligentConversationDesc => 'Soporta conversaciones en lenguaje natural con varios modelos de IA';

  @override
  String get fileProcessing => 'Procesamiento de archivos';

  @override
  String get fileProcessingDesc => 'Soporta la subida de múltiples formatos de archivo como imágenes y documentos';

  @override
  String get historyRecords => 'Registros de historial';

  @override
  String get historyRecordsDesc => 'Guarda automáticamente el historial con memoria de contexto';

  @override
  String get customSettings => 'Ajustes personalizados';

  @override
  String get customSettingsDesc => 'Configura parámetros de API, temas y opciones personalizadas de forma flexible';

  @override
  String get licenses => 'Licencias';

  @override
  String get sponsor => 'Patrocinar';

  @override
  String get sponsorDesc => 'Si esta aplicación te resulta útil, escanea el código para patrocinar y apoyar el desarrollo';

  @override
  String get copyright => '© 2026 幻梦official';

  @override
  String get copyrightNotice => 'Esta aplicación es solo para fines de aprendizaje e investigación';

  @override
  String get copyrightTerms => 'Asegúrate de cumplir con los términos de servicio de la API antes de usarla';

  @override
  String get profileSaved => 'Perfil de usuario guardado';

  @override
  String saveProfileError(String error) {
    return 'Error al guardar el perfil: $error';
  }

  @override
  String get pickAvatarFailed => 'Error al elegir avatar';

  @override
  String get takePhotoFailed => 'Error al tomar foto';

  @override
  String get selectEmojiAvatar => 'Seleccionar emoji de avatar';

  @override
  String get selectAvatar => 'Seleccionar avatar';

  @override
  String get selectFromGallery => 'Seleccionar de la galería';

  @override
  String get takePhoto => 'Tomar foto';

  @override
  String get selectEmoji => 'Seleccionar emoji';

  @override
  String get tapToChangeAvatar => 'Toca para cambiar el avatar';

  @override
  String get username => 'Nombre de usuario';

  @override
  String get usernameHint => 'La IA usará este nombre para dirigirse a ti';

  @override
  String get enterYourUsername => 'Introduce tu nombre de usuario';

  @override
  String get gender => 'Género';

  @override
  String get genderHint => 'Selecciona tu género';

  @override
  String get male => 'Masculino';

  @override
  String get female => 'Femenino';

  @override
  String get selectGender => 'Seleccionar género';

  @override
  String get aboutUserProfile => 'Acerca del perfil de usuario';

  @override
  String get aboutUserProfileContent => '• Avatar: Elige una foto o emoji como avatar, se mostrará en el chat\n• Nombre: La IA usará este nombre en las conversaciones\n• Toda la información se guarda localmente, nunca se sube al servidor';

  @override
  String get selectPresetRole => 'Seleccionar rol predefinido';

  @override
  String get selectPresetRoleMessage => 'Selecciona un rol para aplicar el mensaje del sistema correspondiente';

  @override
  String get closePresetMode => 'Cerrar modo predefinido';

  @override
  String get continueAction => 'Continuar';

  @override
  String get deepThinking => 'Pensamiento profundo';

  @override
  String get rolePlay => 'Juego de rol';

  @override
  String get language => 'Idioma';

  @override
  String get interfaceLanguage => 'Idioma de la interfaz';

  @override
  String get selectInterfaceLanguage => 'Seleccionar idioma de la aplicación';

  @override
  String get thinkChain => 'Cadena de pensamiento';

  @override
  String get expandChain => 'Ver proceso de razonamiento';

  @override
  String get downloadDirectory => 'Directorio de descargas';

  @override
  String get externalStorageDirectory => 'Directorio de almacenamiento externo';

  @override
  String get appDocumentsDirectory => 'Directorio de documentos de la app';

  @override
  String get imagePreview => 'Vista previa de imagen';

  @override
  String get unableToLoadImage => 'No se pudo cargar la imagen';

  @override
  String get errorPrefix => 'Error';

  @override
  String get fileTooLarge => 'Archivo demasiado grande';

  @override
  String fileTooLargeMessage(String size, String limit) {
    return 'El tamaño total de los archivos ($size) excede el límite de $limit. Selecciona archivos más pequeños.';
  }

  @override
  String get fileTooLargeWarning => 'Aviso de archivo grande';

  @override
  String fileTooLargeWarningMessage(String limit, String files) {
    return 'Los siguientes archivos exceden el límite de $limit y podrían no procesarse correctamente:\n\n$files\n\n¿Continuar subida?';
  }

  @override
  String get noValidFiles => 'Sin archivos válidos';

  @override
  String get noValidFilesMessage => 'No se procesó ningún archivo con éxito. Inténtalo de nuevo.';

  @override
  String get selectFileFailed => 'Error al seleccionar archivo';

  @override
  String selectFileFailedMessage(String error) {
    return 'Error: $error';
  }

  @override
  String get user => 'Usuario';

  @override
  String get ai => 'IA';

  @override
  String get unknownError => 'Error desconocido';

  @override
  String attachmentInfo(String fileName, String fileSize, String mimeType) {
    return 'Adjunto: $fileName ($fileSize, $mimeType)';
  }

  @override
  String get attachmentCannotRead => ' - No se puede leer el contenido';

  @override
  String get unknownMimeType => 'Tipo desconocido';

  @override
  String get multimediaNotSupported => '\nNota: DeepSeek no soporta el procesamiento de archivos multimedia como imágenes, videos o audio';

  @override
  String get responseBlocked => 'Respuesta bloqueada por el filtro de seguridad';

  @override
  String apiError(String message, int statusCode) {
    return 'Error de API: $message (Código: $statusCode)';
  }

  @override
  String get configureApiKeyFirst => 'Configura la clave API en los ajustes primero';

  @override
  String get selectModelFirst => 'Selecciona un modelo primero';

  @override
  String get messageInputPlaceholder => 'Escribe un mensaje...';

  @override
  String get configureApiSettingsFirst => 'Configura los ajustes de la API primero';

  @override
  String baseSystemPrompt(String username) {
    return '\"$username\" es el nombre del usuario, úsalo apropiadamente en la conversación y responde en español';
  }

  @override
  String requestTimeout(String error) {
    return 'Tiempo de espera agotado: El servidor tardó demasiado en responder. Revisa tu conexión. Error: $error';
  }

  @override
  String networkConnectionFailed(String error) {
    return 'Error de conexión: No se pudo conectar al servidor. Error: $error';
  }

  @override
  String securityConnectionFailed(String error) {
    return 'Error de conexión segura: Fallo en el saludo SSL/TLS. Revisa la hora del sistema. Error: $error';
  }

  @override
  String connectionError(String error) {
    return 'Error de conexión: Problema de red. Error: $error';
  }

  @override
  String httpProtocolError(String error) {
    return 'Error de protocolo HTTP: Fallo al procesar la solicitud. Error: $error';
  }

  @override
  String networkCommunicationFailed(String error) {
    return 'Fallo en la comunicación de red: $error';
  }

  @override
  String providerFileNotFound(String fileName) {
    return 'El archivo $fileName no existe o ha sido eliminado';
  }

  @override
  String providerFileTooLarge(String fileName, String fileSize) {
    return 'El archivo $fileName ($fileSize) es demasiado grande para procesarlo';
  }

  @override
  String providerFileProcessError(String fileName, String error) {
    return 'Error al procesar el archivo $fileName: $error';
  }

  @override
  String providerFileContent(String fileName, String fileSize, String content) {
    return 'Archivo: $fileName ($fileSize)\nContenido:\n$content';
  }

  @override
  String providerAttachmentCannotRead(String fileName, String fileSize, String mimeType) {
    return 'Adjunto: $fileName ($fileSize, $mimeType) - No se puede leer el contenido';
  }

  @override
  String providerAttachmentInfo(String fileName, String fileSize, String mimeType) {
    return 'Adjunto: $fileName ($fileSize, $mimeType)';
  }

  @override
  String providerTotalSizeExceeded(int limit) {
    return 'El tamaño total de los adjuntos excede el límite de ${limit}MB';
  }

  @override
  String get providerInvalidResponseFormat => 'La API devolvió un formato de respuesta inválido';

  @override
  String get providerMissingMessageField => 'Falta el campo de mensaje en la respuesta de la API';

  @override
  String providerInvalidResponseFormatWithCode(int statusCode) {
    return 'Error API: Formato de respuesta inválido (Código: $statusCode)';
  }

  @override
  String providerApiError(String message, int statusCode) {
    return 'Error API: $message (Código: $statusCode)';
  }

  @override
  String providerStreamingTimeout(int seconds) {
    return 'Tiempo de espera en streaming agotado: No se han recibido datos durante $seconds segundos';
  }

  @override
  String get providerUnknownError => 'Error desconocido';

  @override
  String get providerUser => 'Usuario';

  @override
  String get providerAi => 'IA';

  @override
  String get providerTitleGenSystemPrompt => 'Genera un título en español corto y preciso basado en el idioma del usuario y el contenido de la conversación. Máximo 15 palabras. Solo devuelve el título, sin comillas ni formato adicional.';

  @override
  String providerTitleGenUserPrompt(String conversationSummary) {
    return 'Por favor, genera un título corto en español basado en el contenido de la conversación:\n\n$conversationSummary';
  }

  @override
  String get providerMultimediaNotSupported => '\nNota: DeepSeek no soporta el procesamiento de archivos multimedia';

  @override
  String get providerGeminiInvalidResponse => 'La API de Gemini devolvió un formato de respuesta inválido';

  @override
  String get providerGeminiMissingCandidates => 'Falta el campo \'candidates\' en la respuesta de la API de Gemini';

  @override
  String get providerGeminiInvalidFormat => 'Formato de respuesta de Gemini inválido';

  @override
  String providerGeminiError(String message, int statusCode) {
    return 'Error de la API de Gemini: $message (Código: $statusCode)';
  }

  @override
  String providerGeminiStreamingTimeout(int seconds) {
    return 'Tiempo de espera agotado en Gemini: No se han recibido datos durante $seconds segundos';
  }

  @override
  String providerGeminiInvalidFormatWithCode(int statusCode) {
    return 'Error Gemini: Formato de respuesta inválido (Código: $statusCode)';
  }

  @override
  String get providerResponseBlocked => 'Respuesta bloqueada por el filtro de seguridad';

  @override
  String get platformAndModel => 'Plataformas y Modelos';

  @override
  String get platformAndModelDesc => 'Gestionar plataformas de IA y configuraciones de modelos';

  @override
  String get addPlatform => 'Añadir plataforma';

  @override
  String get editPlatform => 'Editar plataforma';

  @override
  String get platformType => 'Tipo de plataforma';

  @override
  String get platformNamePlaceholder => 'Nombre de la plataforma';

  @override
  String get endpointPlaceholder => 'URL del punto de acceso';

  @override
  String get configured => 'Configurado';

  @override
  String get notConfigured => 'No configurado';

  @override
  String get models => 'modelos';

  @override
  String get available => 'Disponible';

  @override
  String get current => 'Actual';

  @override
  String get currentModel => 'Modelo actual';

  @override
  String get manageModels => 'Gestionar modelos';

  @override
  String get refreshModels => 'Actualizar lista';

  @override
  String get noModelsAvailable => 'No hay modelos disponibles';

  @override
  String get noModelSelected => 'Ningún modelo seleccionado';

  @override
  String get modelsRefreshed => 'Lista de modelos actualizada';

  @override
  String refreshModelsError(String error) {
    return 'Error al actualizar modelos: $error';
  }

  @override
  String get deletePlatform => 'Eliminar plataforma';

  @override
  String deletePlatformConfirm(String name) {
    return '¿Estás seguro de que quieres eliminar la plataforma \"$name\"?';
  }

  @override
  String get switchToPlatform => 'Cambiar a esta plataforma';

  @override
  String switchedToPlatform(String name) {
    return 'Cambiado a $name';
  }

  @override
  String get addModelTitle => 'Añadir modelo';

  @override
  String get modelNamePh => 'Nombre del modelo';

  @override
  String get addModelBtn => 'Añadir';

  @override
  String get deleteModelTitle => 'Eliminar modelo';

  @override
  String deleteModelConfirm(String model) {
    return '¿Estás seguro de que quieres eliminar el modelo \"$model\"?';
  }

  @override
  String get deleteModelBtn => 'Eliminar seleccionado';

  @override
  String get selectModelToDelete => 'Selecciona un modelo para eliminar primero';

  @override
  String get add => 'Añadir';

  @override
  String get addNewModel => 'Añadir nuevo modelo';

  @override
  String get clickAddToCreate => 'Toca el botón + para añadir un modelo';

  @override
  String get noPlatformsConfigured => 'No hay plataformas configuradas';

  @override
  String get addPlatformHint => 'Toca el botón + en la esquina superior derecha para añadir tu primera plataforma de IA';

  @override
  String get exportConversation => 'Exportar conversación';

  @override
  String get exportFormat => 'Formato de exportación';

  @override
  String get exportFormatTxt => 'Texto plano (.txt)';

  @override
  String get exportFormatJson => 'JSON (.json)';

  @override
  String get exportFormatLumenflow => 'Lumenflow (.lumenflow)';

  @override
  String get exportFormatPdf => 'PDF (.pdf)';

  @override
  String get exportConversationSuccess => 'Conversación exportada con éxito';

  @override
  String get exportConversationFailed => 'Fallo al exportar conversación';

  @override
  String exportConversationError(String error) {
    return 'Error al exportar la conversación: $error';
  }

  @override
  String get exportConversationTitle => 'Título: ';

  @override
  String get exportCreatedTime => 'Creado el: ';

  @override
  String get exportUpdatedTime => 'Actualizado el: ';

  @override
  String get exportMessageCount => 'Recuento de mensajes: ';

  @override
  String get exportReasoningProcess => '[Proceso de razonamiento]';

  @override
  String exportAttachments(int count) {
    return '[Adjuntos: $count]';
  }

  @override
  String get exportBytes => 'bytes';

  @override
  String get exportConversationNotFound => 'Conversación no encontrada';

  @override
  String get exportThinkingProcess => 'Proceso de pensamiento';

  @override
  String get exportAttachmentsLabel => 'Adjuntos';

  @override
  String get notificationSettings => 'Notificaciones';

  @override
  String get enableNotification => 'Habilitar notificaciones';

  @override
  String get enableNotificationDesc => 'Recibir notificación cuando se complete la respuesta de la IA';

  @override
  String get dataManagement => 'Gestión de datos';

  @override
  String get liveUpdateAIResponse => 'Respuesta';

  @override
  String get languageChanged => 'Idioma cambiado';

  @override
  String get restartAppToApplyLanguage => 'Por favor, reinicia la aplicación para aplicar el cambio de idioma';

  @override
  String get loading => 'Cargando';

  @override
  String get copyMessage => 'Copiar mensaje';

  @override
  String get copySuccess => 'Copiado al portapapeles';

  @override
  String get copyFailed => 'Fallo al copiar';

  @override
  String copyError(String error) {
    return 'Error al copiar: $error';
  }

  @override
  String get copySuccessTitle => 'Copiado con éxito';

  @override
  String get copyFailedTitle => 'Fallo al copiar';

  @override
  String get copyCode => 'Copiar';

  @override
  String get copied => 'Copiado';

  @override
  String get aiResponseDisclaimer => 'El contenido es solo de referencia, verifíquelo cuidadosamente';

  @override
  String get advancedSettings => 'Avanzado';

  @override
  String get advancedSettingsSubtitle => 'Configurar comportamiento de la app';

  @override
  String get userProfileSubtitle => 'Personaliza tu cuenta';

  @override
  String get platformAndModelSubtitle => 'Configura plataformas y modelos de IA';

  @override
  String get apiTypeSubtitle => 'Ajustes de conexión de la API';

  @override
  String get modelSettingsSubtitle => 'Ajusta el comportamiento de respuesta';

  @override
  String get historyConversationSubtitle => 'Gestionar historial de chats';

  @override
  String get toolsSettingsSubtitle => 'Configurar herramientas externas';

  @override
  String get appearanceSubtitle => 'Personaliza la apariencia';

  @override
  String get credits => 'Créditos';

  @override
  String get creditsMainDeveloper => 'Desarrollador principal';

  @override
  String get creditsAppImprovementSuggestions => 'Sugerencias de mejora';

  @override
  String get creditsAppImprovementAndCode => 'Mejoras y código parcial';

  @override
  String get creditsBugTestingAndCode => 'Pruebas de errores y código parcial';

  @override
  String get creditsDescription => 'Agradecimientos especiales a los siguientes colaboradores por su inestimable apoyo:';

  @override
  String get contributors => 'Colaboradores';

  @override
  String get editMessage => 'Editar mensaje';

  @override
  String get regenerateResponse => 'Regenerar respuesta';

  @override
  String get resubmit => 'Reenviar';

  @override
  String get editMessageHint => 'Editar contenido del mensaje';

  @override
  String get confirmEdit => 'Confirmar edición';

  @override
  String get editMessageDialogTitle => 'Editar mensaje';

  @override
  String get regenerateConfirm => '¿Regenerar esta respuesta de la IA?';

  @override
  String get messageOptions => 'Opciones del mensaje';

  @override
  String get presetManagement => 'Gestión de ajustes predefinidos';

  @override
  String get presetManagementSubtitle => 'Gestionar prompts internos e importados';

  @override
  String get builtInPresets => 'Predefinidos';

  @override
  String get userPresets => 'Ajustes de usuario';

  @override
  String get noPresetsAvailable => 'No hay ajustes disponibles';

  @override
  String get importXmlHint => 'Toca + en la esquina superior derecha para importar archivos XML';

  @override
  String get importPresetDialogTitle => 'Importar ajuste';

  @override
  String get presetNamePlaceholder => 'Nombre del ajuste';

  @override
  String get descriptionPlaceholder => 'Descripción';

  @override
  String get authorPlaceholder => 'Autor';

  @override
  String get importButton => 'Importar';

  @override
  String get deletePresetDialogTitle => 'Eliminar ajuste';

  @override
  String deletePresetConfirm(String presetName) {
    return '¿Estás seguro de que quieres eliminar el ajuste \"$presetName\"?';
  }

  @override
  String presetDeletedSuccess(String presetName) {
    return 'Eliminado: $presetName';
  }

  @override
  String importFailedError(String error) {
    return 'Fallo al importar: $error';
  }

  @override
  String deleteFailedError(String error) {
    return 'Fallo al eliminar: $error';
  }

  @override
  String get filePathError => 'No se pudo obtener la ruta del archivo';

  @override
  String get authorLabel => 'Autor:';

  @override
  String get versionLabel => 'Versión:';

  @override
  String get descriptionLabel => 'Descripción:';

  @override
  String get systemPromptLabel => 'Mensaje del sistema:';

  @override
  String get closeButton => 'Cerrar';

  @override
  String loadPresetsFailed(String error) {
    return 'Fallo al cargar ajustes: $error';
  }

  @override
  String get roleCardGeneratorLink => 'Generador de cartas de rol';

  @override
  String get httpServerSwitchLabel => 'Servidor del generador';

  @override
  String get httpServerStatusRunning => 'En ejecución';

  @override
  String get httpServerStatusStopped => 'Detenido';

  @override
  String get openGeneratorButton => 'Abrir generador';

  @override
  String get httpServerDescription => 'Servidor en el puerto 5050 para el generador de cartas de rol.';

  @override
  String get httpServerNotRunningTitle => 'Servidor detenido';

  @override
  String get httpServerNotRunningMessage => 'El servidor del generador no está activo. ¿Deseas iniciarlo?';

  @override
  String get startServerButton => 'Iniciar';

  @override
  String get httpServerToggleTooltip => 'Alternar estado del servidor HTTP';

  @override
  String openLinkFailed(String error) {
    return 'Error al abrir el enlace: $error';
  }

  @override
  String get currentTime => 'La siguiente es la hora actual; no la menciones a menos que el usuario lo pregunte:';

  @override
  String httpServerOperationFailed(String error) {
    return 'Fallo en el servidor HTTP: $error';
  }

  @override
  String get chatBackground => 'Fondo de chat';

  @override
  String get selectBackgroundImage => 'Seleccionar fondo';

  @override
  String get changeBackgroundImage => 'Cambiar fondo';

  @override
  String get selectBackgroundImageDesc => 'Elige una imagen para el fondo del chat';

  @override
  String get currentBackgroundImage => 'Imagen de fondo establecida';

  @override
  String get clear => 'Limpiar';

  @override
  String get backgroundOpacity => 'Opacidad del fondo';

  @override
  String get backgroundOpacityDesc => 'Ajusta la transparencia de la imagen de fondo';

  @override
  String get selectImageFailed => 'Fallo al seleccionar imagen';

  @override
  String get clearBackgroundImage => 'Quitar fondo';

  @override
  String get clearBackgroundImageConfirm => '¿Estás seguro de que quieres quitar la imagen de fondo?';

  @override
  String get birthday => 'Cumpleaños';

  @override
  String get birthdayHint => 'Selecciona tu fecha de nacimiento';

  @override
  String get selectBirthday => 'Seleccionar fecha';

  @override
  String get toolManagement => 'Gestión de herramientas';

  @override
  String get promptTools => 'Herramientas';

  @override
  String get addTimeToPrompt => 'Hora';

  @override
  String get addTimeToPromptDesc => 'Obtener hora actual';
}
