/// API бота GPN (тот же хост, что мини-апп).
const String kApiBase = String.fromEnvironment(
  'GPN_API_BASE',
  defaultValue: 'https://giga-gpn.space',
);
