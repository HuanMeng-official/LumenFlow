import 'package:flutter/cupertino.dart';
import 'conversation_list_screen.dart';
import 'chat_screen.dart';

/// 响应式聊天布局组件
///
/// 根据屏幕宽度自动选择布局：
/// - 小屏幕（手机）：显示聊天界面，通过导航打开对话列表
/// - 大屏幕（平板/桌面）：左右分栏布局，左侧对话列表，右侧聊天界面
class ResponsiveChatLayout extends StatefulWidget {
  const ResponsiveChatLayout({super.key});

  @override
  State<ResponsiveChatLayout> createState() => _ResponsiveChatLayoutState();
}

class _ResponsiveChatLayoutState extends State<ResponsiveChatLayout> {
  /// 当前选中的对话ID，用于在对话列表和聊天界面之间同步状态
  String? _currentConversationId;

  /// 对话列表的key，用于强制刷新对话列表
  int _conversationListKey = 0;

  /// 平板布局的断点宽度（逻辑像素）
  /// 通常平板宽度大于600dp，这里设置为768dp以适配更多平板设备
  static const double _tabletBreakpoint = 768.0;

  /// 判断当前是否为平板布局
  bool get _isTabletLayout {
    final mediaQuery = MediaQuery.of(context);
    return mediaQuery.size.width >= _tabletBreakpoint;
  }

  /// 处理对话选择
  void _handleConversationSelected(String? conversationId) {
    setState(() {
      _currentConversationId = conversationId;
    });
  }

  /// 刷新对话列表
  void _refreshConversationList() {
    setState(() {
      _conversationListKey++;
    });
  }

  /// 构建平板布局（左右分栏）
  Widget _buildTabletLayout() {
    return Row(
      children: [
        // 左侧：对话列表（宽度占总宽的30%，最大宽度400）
        Container(
          width: MediaQuery.of(context).size.width * 0.3,
          constraints: const BoxConstraints(maxWidth: 400),
          child: ConversationListScreen(
            key: ValueKey('conversation_list_$_conversationListKey'),
            onConversationSelected: _handleConversationSelected,
            autoPopOnSelect: false, // 平板模式下不自动弹出
          ),
        ),
        // 右侧：聊天界面（宽度占总宽的70%）
        Expanded(
          child: ChatScreen(
            // 传递当前对话ID，ChatScreen根据此ID加载对话
            initialConversationId: _currentConversationId,
            // 隐藏左侧的对话列表按钮，因为对话列表已经在左侧显示
            hideConversationListButton: true,
            // 平板模式下不自动创建对话，由对话列表负责创建
            autoCreateConversation: false,
            // 对话更新时刷新对话列表
            onConversationUpdated: _refreshConversationList,
          ),
        ),
      ],
    );
  }

  /// 构建手机布局（单屏聊天界面）
  Widget _buildMobileLayout() {
    // 手机布局下，使用原始的ChatScreen，保持原有的导航逻辑
    // ChatScreen内部通过导航打开ConversationListScreen并处理对话选择
    // 传递当前对话ID，确保平板/手机切换时对话不丢失
    return ChatScreen(
      initialConversationId: _currentConversationId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _isTabletLayout ? _buildTabletLayout() : _buildMobileLayout();
  }
}