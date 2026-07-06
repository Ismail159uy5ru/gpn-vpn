/// API бота GPN (тот же хост, что мини-апп).
const String kApiBase = String.fromEnvironment(
  'GPN_API_BASE',
  defaultValue: 'https://giga-gpn.space',
);

/// Запасное имя бота, если /app/ping недоступен.
const String kDefaultBotUsername = String.fromEnvironment(
  'GPN_BOT_USERNAME',
  defaultValue: 'giga_V_P_N_Bot',
);
