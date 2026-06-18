/// Defines the contract between AI-generated UI widgets and app state.
///
/// ## Path format
/// Paths follow the convention: `/domain/entity/property`
///
/// ## Domains
///
/// ### `/filter/*` — Data filtering
/// Used by list widgets to filter data by entity and property.
///
/// | Path | Type | Description |
/// |---|---|---|
/// | `/filter/tasks/priority` | `String` | `high`, `normal`, `low` |
/// | `/filter/tasks/done` | `bool` | `true`, `false` |
/// | `/filter/habits/completed` | `bool` | Whether habit was done today |
/// | `/filter/notes/tag` | `String` | Filter notes by tag |
///
/// ### `/form/*` — Form field bindings
/// Used by input widgets to read/write form values.
///
/// | Path | Type | Description |
/// |---|---|---|
/// | `/form/task/title` | `String` | New task title |
/// | `/form/task/priority` | `String` | Selected priority |
/// | `/form/habit/name` | `String` | New habit name |
/// | `/form/note/content` | `String` | Note content |
/// | `/form/focus/minutes` | `int` | Focus session duration |
///
/// ### `/settings/*` — App settings
/// Used by preference and setting widgets.
///
/// | Path | Type | Description |
/// |---|---|---|
/// | `/settings/model/tier` | `String` | `e2b`, `e4b` |
/// | `/settings/profile/name` | `String` | User's display name |
/// | `/settings/profile/role` | `String` | User's focus role |
/// | `/settings/premium` | `bool` | Whether premium is active |
///
/// ### `/data/*` — Live data from Drift
/// Used by display widgets to show current state. Read-only.
///
/// | Path | Type | Description |
/// |---|---|---|
/// | `/data/tasks/open` | `int` | Count of open tasks |
/// | `/data/tasks/completed` | `int` | Count of completed tasks |
/// | `/data/habits/today/completed` | `int` | Habits done today |
/// | `/data/habits/today/total` | `int` | Total habits |
/// | `/data/focus/minutes` | `int` | Today's focus minutes |
/// | `/data/streak` | `int` | Current streak |
/// | `/data/mood/today` | `String?` | Today's mood emoji |
///
/// ### `/action/*` — Trigger actions
/// Used by button and tappable widgets.
///
/// | Path | Type | Description |
/// |---|---|---|
/// | `/action/navigate` | `Map` | Switch tab: `{"tab": "tasks"}` |
/// | `/action/create_task` | `Map` | Create task: `{"title": "...", "priority": "..."}` |
/// | `/action/create_habit` | `Map` | Create habit: `{"name": "...", "icon": "..."}` |
/// | `/action/create_note` | `Map` | Create note: `{"content": "..."}` |
/// | `/action/start_focus` | `Map` | Start focus: `{"minutes": 25}` |
/// | `/action/show_snackbar` | `Map` | Show message: `{"message": "..."}` |
///
/// ## Usage in A2UI JSON
///
/// ```json
/// {
///   "widget": "Button",
///   "props": {
///     "label": "View tasks"
///   },
///   "onTap": {
///     "action": "navigate",
///     "params": {"tab": "tasks"}
///   }
/// }
/// ```
///
/// ```json
/// {
///   "widget": "Chip",
///   "props": {
///     "label": "High priority",
///     "color": "error",
///     "selected": true
///   },
///   "onTap": {
///     "action": "filter",
///     "params": {"path": "/filter/tasks/priority", "value": "high"}
///   }
/// }
/// ```
class DataModelSchema {
  DataModelSchema._();

  /// All valid domain prefixes.
  static const List<String> domains = [
    'filter',
    'form',
    'settings',
    'data',
    'action',
  ];

  /// Validate that a path follows the schema.
  static bool isValidPath(String path) {
    if (!path.startsWith('/')) return false;
    final parts = path.split('/');
    if (parts.length < 3) return false;
    return domains.contains(parts[1]);
  }

  /// Extract the domain from a path.
  static String? domain(String path) {
    final parts = path.split('/');
    return parts.length >= 2 ? parts[1] : null;
  }

  /// Whether the path refers to a read-only data value.
  static bool isReadOnly(String path) {
    final d = domain(path);
    return d == 'data' || d == 'action';
  }

  /// Whether the path can be written (form/settings input).
  static bool isWritable(String path) {
    final d = domain(path);
    return d == 'form' || d == 'settings';
  }

  /// Whether the path is a filter.
  static bool isFilter(String path) => domain(path) == 'filter';
}
