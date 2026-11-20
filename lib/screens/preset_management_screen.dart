import 'package:cupertino_ui/cupertino_ui.dart';

import '../l10n/app_localizations.dart';
import '../models/preset_load_result.dart';
import '../models/prompt_preset.dart';
import '../services/http_server_service.dart';
import '../services/preset_repository.dart';
import '../services/preset_ui_actions.dart';
import '../utils/app_theme.dart';
import '../utils/preset_filter.dart';
import '../utils/preset_illustration.dart';
import '../widgets/preset_avatar.dart';
import '../widgets/preset_detail_view.dart';
import '../widgets/settings/settings_section.dart';
import '../widgets/settings/settings_switch_tile.dart';

/// 预设管理与角色画廊界面。
///
/// - 移动端主壳（`sidebarOnly == false`）展示 2 列立绘角色画廊 + 本地角色卡生成器卡片，
///   点击卡片通过原生 Push 导航进入全屏 `PresetDetailPage`。
/// - 桌面端左侧栏（`sidebarOnly == true`）展示紧凑角色列表，配合主舞台 `PresetDetailView` 组成双栏工作室。
class PresetManagementScreen extends StatefulWidget {
  const PresetManagementScreen({
    super.key,
    this.embedded = false,
    this.sidebarOnly = false,
    this.selectedPresetId,
    this.onPresetSelected,
    this.onStartChatWithPreset,
  });

  final bool embedded;
  final bool sidebarOnly;
  final String? selectedPresetId;
  final ValueChanged<PromptPreset>? onPresetSelected;
  final ValueChanged<PromptPreset>? onStartChatWithPreset;

  @override
  State<PresetManagementScreen> createState() => _PresetManagementScreenState();
}

class _PresetManagementScreenState extends State<PresetManagementScreen> {
  final PresetRepository _presetRepository = PresetRepository.instance;
  final HttpServerService _httpServerService = HttpServerService();

  List<PromptPreset> _builtInPresets = [];
  List<PromptPreset> _userPresets = [];
  List<PresetLoadIssue> _issues = const [];
  bool _showIssues = false;
  bool _isLoading = true;
  String? _errorMessage;
  String? _filterLanguage;
  String? _filterTag;

  bool _isHttpServerRunning = false;
  String? _httpServerUrl;

  @override
  void initState() {
    super.initState();
    _presetRepository.addListener(_onRepositoryChanged);
    _httpServerService.isRunningNotifier.addListener(_onHttpServerStateChanged);
    _httpServerService.serverUrlNotifier.addListener(_onHttpServerStateChanged);
    _syncFromRepository();
    _syncHttpServerState();
    _loadPresets();
  }

  @override
  void dispose() {
    _presetRepository.removeListener(_onRepositoryChanged);
    _httpServerService.isRunningNotifier.removeListener(
      _onHttpServerStateChanged,
    );
    _httpServerService.serverUrlNotifier.removeListener(
      _onHttpServerStateChanged,
    );
    super.dispose();
  }

  void _syncHttpServerState() {
    _isHttpServerRunning = _httpServerService.isRunning;
    _httpServerUrl = _httpServerService.serverUrl;
  }

  void _onHttpServerStateChanged() {
    if (!mounted) return;
    setState(_syncHttpServerState);
  }

  void _onRepositoryChanged() {
    if (!mounted) return;
    setState(_syncFromRepository);
  }

  void _syncFromRepository() {
    final all = _presetRepository.presets;
    _builtInPresets = all.where((preset) => !preset.isUserPreset).toList();
    _userPresets = all.where((preset) => preset.isUserPreset).toList();
    _issues = _presetRepository.issues;
  }

  Future<void> _loadPresets() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await _presetRepository.ensureLoaded();
      if (!mounted) return;
      setState(() {
        _syncFromRepository();
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _errorMessage = l10n.loadPresetsFailed(error.toString());
        _isLoading = false;
      });
    }
  }

  Future<void> _handleImport() async {
    final imported = await PresetUiActions.pickAndImportPreset(context);
    if (imported != null && mounted) {
      widget.onPresetSelected?.call(imported);
    }
  }

  String _issuePresetName(PresetLoadIssue issue) {
    for (final preset in [..._builtInPresets, ..._userPresets]) {
      if (preset.id == issue.presetId) return preset.name;
    }
    return issue.message;
  }

  String _issueText(PresetLoadIssue issue, AppLocalizations l10n) {
    return switch (issue.type) {
      PresetIssueType.builtInMetaMissing =>
        l10n.presetIssueBuiltInMetaMissing(issue.message),
      PresetIssueType.userJsonCorrupt => issue.backupName != null
          ? l10n.presetIssueUserJsonCorrupt(issue.backupName!)
          : l10n.presetIssueUserJsonCorruptNoBackup(issue.message),
      PresetIssueType.userEntryInvalid =>
        l10n.presetIssueUserEntryInvalid(issue.message),
      PresetIssueType.userJsonWriteFailed =>
        l10n.presetIssueUserJsonWriteFailed(issue.message),
      PresetIssueType.userMigrationBackupFailed =>
        l10n.presetIssueUserMigrationBackupFailed(issue.message),
      PresetIssueType.cardFileMissing =>
        l10n.presetIssueCardFileMissing(_issuePresetName(issue)),
      PresetIssueType.cardFileUnreadable =>
        l10n.presetIssueCardFileUnreadable(_issuePresetName(issue)),
      PresetIssueType.worldInfoInvalid =>
        l10n.presetIssueWorldInfoInvalid(_issuePresetName(issue)),
      PresetIssueType.growthInvalid =>
        l10n.presetIssueGrowthInvalid(_issuePresetName(issue)),
    };
  }

  Widget _buildIssuesBanner(AppLocalizations l10n, {bool compact = false}) {
    final warning = CupertinoColors.systemOrange.resolveFrom(context);
    return Container(
      margin: EdgeInsets.fromLTRB(
        compact ? 10 : 16,
        compact ? 8 : 12,
        compact ? 10 : 16,
        0,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: warning.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: warning.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _showIssues = !_showIssues),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.exclamationmark_triangle,
                  size: 16,
                  color: warning,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${l10n.presetIssuesTitle} · ${l10n.presetIssuesCount(_issues.length)}',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: warning,
                    ),
                  ),
                ),
                Icon(
                  _showIssues
                      ? CupertinoIcons.chevron_up
                      : CupertinoIcons.chevron_down,
                  size: 13,
                  color: warning,
                ),
              ],
            ),
          ),
          if (_showIssues) ...[
            const SizedBox(height: 6),
            for (final issue in _issues)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '• ${_issueText(issue, l10n)}',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppTokens.labelSecondary(context),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? AppTokens.accentSoft(context)
              : AppTokens.fill(context),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected
                ? AppTokens.accent(context)
                : AppTokens.labelSecondary(context),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBar(AppLocalizations l10n, {bool compact = false}) {
    final all = [..._builtInPresets, ..._userPresets];
    final languages = all
        .map((preset) => preset.language)
        .whereType<String>()
        .toSet()
        .toList()
      ..sort();
    final tags = all.expand((preset) => preset.tags).toSet().toList()..sort();
    if (languages.isEmpty && tags.isEmpty) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.fromLTRB(compact ? 10 : 16, 10, compact ? 10 : 16, 4),
      child: Row(
        children: [
          _filterChip(
            l10n.presetFilterAll,
            _filterLanguage == null && _filterTag == null,
            () => setState(() {
              _filterLanguage = null;
              _filterTag = null;
            }),
          ),
          for (final language in languages)
            _filterChip(
              language.toUpperCase(),
              _filterLanguage == language && _filterTag == null,
              () => setState(() {
                _filterLanguage = language;
                _filterTag = null;
              }),
            ),
          for (final tag in tags)
            _filterChip(
              '#$tag',
              _filterTag == tag,
              () => setState(() {
                _filterTag = tag;
                _filterLanguage = null;
              }),
            ),
        ],
      ),
    );
  }

  void _openMobileDetail(PromptPreset preset) {
    Navigator.of(context, rootNavigator: true).push(
      CupertinoPageRoute(
        builder: (_) => PresetDetailPage(
          preset: preset,
          onStartChat: widget.onStartChatWithPreset == null
              ? null
              : () => widget.onStartChatWithPreset!(preset),
          onEdit: preset.isUserPreset
              ? (item) => PresetUiActions.editPreset(context, item)
              : null,
          onDuplicate: (item) => PresetUiActions.duplicatePreset(context, item),
          onExport: (item) => PresetUiActions.exportPreset(context, item),
          onDelete: preset.isUserPreset
              ? (item) => PresetUiActions.confirmAndDeletePreset(context, item)
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final builtIn = filterPresets(
      _builtInPresets,
      language: _filterLanguage,
      tag: _filterTag,
    );
    final userPresets = filterPresets(
      _userPresets,
      language: _filterLanguage,
      tag: _filterTag,
    );
    final hasAnyPresets = _builtInPresets.isNotEmpty || _userPresets.isNotEmpty;
    final hasActiveFilter = _filterLanguage != null || _filterTag != null;

    if (widget.sidebarOnly) {
      return _buildSidebarBody(
        context,
        l10n,
        builtIn: builtIn,
        userPresets: userPresets,
        hasAnyPresets: hasAnyPresets,
        hasActiveFilter: hasActiveFilter,
      );
    }

    final body = _isLoading
        ? const Center(child: CupertinoActivityIndicator())
        : _errorMessage != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTokens.labelSecondary(context)),
                  ),
                ),
              )
            : _buildGalleryBody(
                context,
                l10n,
                builtIn: builtIn,
                userPresets: userPresets,
                hasAnyPresets: hasAnyPresets,
                hasActiveFilter: hasActiveFilter,
              );

    if (widget.embedded) {
      return ColoredBox(color: AppTokens.groupedBg(context), child: body);
    }

    return CupertinoPageScaffold(
      backgroundColor: AppTokens.groupedBg(context),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppTokens.bg(context),
        middle: Text(l10n.characters),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _handleImport,
          child: const Icon(CupertinoIcons.plus),
        ),
        border: Border(
          bottom: BorderSide(
            color: AppTokens.separator(context),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(child: body),
    );
  }

  Widget _buildSidebarBody(
    BuildContext context,
    AppLocalizations l10n, {
    required List<PromptPreset> builtIn,
    required List<PromptPreset> userPresets,
    required bool hasAnyPresets,
    required bool hasActiveFilter,
  }) {
    if (_isLoading) {
      return const Center(child: CupertinoActivityIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            _errorMessage!,
            style: TextStyle(
              fontSize: 13,
              color: AppTokens.labelSecondary(context),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_issues.isNotEmpty) _buildIssuesBanner(l10n, compact: true),
        if (hasAnyPresets) _buildFilterBar(l10n, compact: true),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 12),
            children: [
              if (builtIn.isNotEmpty) ...[
                _sidebarSectionHeader(context, l10n.builtInPresets),
                for (final preset in builtIn)
                  _buildSidebarRow(context, preset),
              ],
              if (userPresets.isNotEmpty) ...[
                _sidebarSectionHeader(context, l10n.userPresets),
                for (final preset in userPresets)
                  _buildSidebarRow(context, preset),
              ],
              if (hasAnyPresets &&
                  builtIn.isEmpty &&
                  userPresets.isEmpty &&
                  hasActiveFilter)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    l10n.presetFilterNoResults,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTokens.labelSecondary(context),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: AppTokens.separator(context),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.httpServerSwitchLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTokens.label(context),
                      ),
                    ),
                    Text(
                      _isHttpServerRunning
                          ? (_httpServerUrl ?? l10n.httpServerStatusRunning)
                          : l10n.httpServerStatusStopped,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: _isHttpServerRunning
                            ? AppTokens.green(context)
                            : AppTokens.labelTertiary(context),
                      ),
                    ),
                  ],
                ),
              ),
              if (_isHttpServerRunning && _httpServerUrl != null)
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: const Size(24, 24),
                  onPressed: () => PresetUiActions.launchRoleCardGenerator(
                    context,
                  ),
                  child: Icon(
                    CupertinoIcons.arrow_up_right_square,
                    size: 16,
                    color: AppTokens.accent(context),
                  ),
                ),
              CupertinoSwitch(
                value: _isHttpServerRunning,
                onChanged: (_) => PresetUiActions.toggleHttpServer(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sidebarSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: AppTokens.labelTertiary(context),
        ),
      ),
    );
  }

  Widget _buildSidebarRow(BuildContext context, PromptPreset preset) {
    final l10n = AppLocalizations.of(context)!;
    final isSelected = widget.selectedPresetId == preset.id;
    final fontFallback =
        cjkFontFallbackForLocale(Localizations.maybeLocaleOf(context));

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (widget.onPresetSelected != null) {
          widget.onPresetSelected!(preset);
        } else {
          _openMobileDetail(preset);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        margin: const EdgeInsets.symmetric(vertical: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTokens.rowActive(context)
              : CupertinoColors.transparent,
          borderRadius: BorderRadius.circular(AppTokens.radiusSm),
        ),
        child: Row(
          children: [
            PresetAvatar(preset: preset, size: 36, showBorder: true),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          preset.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            fontFamilyFallback: fontFallback,
                            color: preset.isBroken
                                ? AppTokens.labelTertiary(context)
                                : AppTokens.label(context),
                          ),
                        ),
                      ),
                      if (preset.hasGrowth) ...[
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: AppTokens.accentSoft(context),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            l10n.growthBadgeLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppTokens.accent(context),
                              fontFamilyFallback: fontFallback,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (preset.description.trim().isNotEmpty) ...[
                    const SizedBox(height: 1.5),
                    Text(
                      preset.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontFamilyFallback: fontFallback,
                        color: AppTokens.labelSecondary(context),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGalleryBody(
    BuildContext context,
    AppLocalizations l10n, {
    required List<PromptPreset> builtIn,
    required List<PromptPreset> userPresets,
    required bool hasAnyPresets,
    required bool hasActiveFilter,
  }) {
    return CustomScrollView(
      slivers: [
        if (_issues.isNotEmpty)
          SliverToBoxAdapter(child: _buildIssuesBanner(l10n)),
        if (hasAnyPresets)
          SliverToBoxAdapter(child: _buildFilterBar(l10n)),
        if (builtIn.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: _gallerySectionTitle(context, l10n.builtInPresets),
          ),
          _buildPresetGridSliver(builtIn),
        ],
        if (userPresets.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: _gallerySectionTitle(context, l10n.userPresets),
          ),
          _buildPresetGridSliver(userPresets),
        ],
        if (hasAnyPresets &&
            builtIn.isEmpty &&
            userPresets.isEmpty &&
            hasActiveFilter)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                l10n.presetFilterNoResults,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTokens.labelSecondary(context)),
              ),
            ),
          ),
        if (!hasAnyPresets)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(36),
              child: Column(
                children: [
                  Icon(
                    CupertinoIcons.person_2,
                    size: 48,
                    color: AppTokens.labelTertiary(context),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.noPresetsAvailable,
                    style: TextStyle(color: AppTokens.labelSecondary(context)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.importXmlHint,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTokens.labelTertiary(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 32),
            child: SettingsSection(
              title: l10n.httpServerSwitchLabel,
              footer: l10n.httpServerDescription,
              children: [
                SettingsSwitchTile(
                  title: l10n.httpServerSwitchLabel,
                  subtitle: _isHttpServerRunning
                      ? (_httpServerUrl ?? l10n.httpServerStatusRunning)
                      : l10n.httpServerStatusStopped,
                  value: _isHttpServerRunning,
                  onChanged: (_) => PresetUiActions.toggleHttpServer(context),
                ),
                if (_isHttpServerRunning && _httpServerUrl != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                    child: SizedBox(
                      width: double.infinity,
                      child: CupertinoButton(
                        color: AppTokens.accentSoft(context),
                        borderRadius: BorderRadius.circular(10),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        onPressed: () =>
                            PresetUiActions.launchRoleCardGenerator(context),
                        child: Text(
                          l10n.openGeneratorButton,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTokens.accent(context),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _gallerySectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: AppTokens.labelSecondary(context),
        ),
      ),
    );
  }

  Widget _buildPresetGridSliver(List<PromptPreset> presets) {
    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = width >= 900
        ? 4
        : width >= 600
            ? 3
            : 2;

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.66,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _PortraitPresetCard(
            preset: presets[index],
            onTap: () => _openMobileDetail(presets[index]),
          ),
          childCount: presets.length,
        ),
      ),
    );
  }
}

/// 移动端立绘风 2 列角色画廊卡片。
class _PortraitPresetCard extends StatelessWidget {
  const _PortraitPresetCard({
    required this.preset,
    required this.onTap,
  });

  final PromptPreset preset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final illustration = presetIllustrationProvider(preset);
    final fontFallback =
        cjkFontFallbackForLocale(Localizations.maybeLocaleOf(context));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppTokens.elevatedSurface(context),
          borderRadius: BorderRadius.circular(AppTokens.radiusLg),
          border: Border.all(
            color: AppTokens.separator(context),
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                color: AppTokens.fillSoft(context),
                child: illustration != null
                    ? Image(
                        image: illustration,
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                        errorBuilder: (_, _, _) => Center(
                          child: PresetAvatar(
                            preset: preset,
                            size: 54,
                            showBorder: true,
                          ),
                        ),
                      )
                    : Center(
                        child: PresetAvatar(
                          preset: preset,
                          size: 54,
                          showBorder: true,
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          preset.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            fontFamilyFallback: fontFallback,
                            color: preset.isBroken
                                ? AppTokens.labelTertiary(context)
                                : AppTokens.label(context),
                          ),
                        ),
                      ),
                      if (preset.hasGrowth) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5.5,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: AppTokens.accentSoft(context),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            l10n.growthBadgeLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppTokens.accent(context),
                              fontFamilyFallback: fontFallback,
                            ),
                          ),
                        ),
                        if (preset.language != null) const SizedBox(width: 5),
                      ],
                      if (preset.language != null)
                        Text(
                          preset.language!.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: AppTokens.labelTertiary(context),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    preset.isBroken
                        ? l10n.presetBrokenLabel
                        : (preset.description.trim().isNotEmpty
                            ? preset.description
                            : (preset.author.trim().isNotEmpty
                                ? preset.author
                                : 'v${preset.version}')),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      fontFamilyFallback: fontFallback,
                      color: preset.isBroken
                          ? AppTokens.red(context)
                          : AppTokens.labelSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
