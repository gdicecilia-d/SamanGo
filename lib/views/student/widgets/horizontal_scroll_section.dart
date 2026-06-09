// Componente reutilizable para secciones horizontales 
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HorizontalScrollSection extends StatefulWidget {
  final String title;
  final List<Widget> children;
  final bool showTitle;
  final double scrollSpeed;

  const HorizontalScrollSection({
    super.key,
    required this.title,
    required this.children,
    this.showTitle = true,
    this.scrollSpeed = 200,
  });

  @override
  State<HorizontalScrollSection> createState() => _HorizontalScrollSectionState();
}

class _HorizontalScrollSectionState extends State<HorizontalScrollSection> {
  final ScrollController _scrollController = ScrollController();
  bool _showLeftArrow = false;
  bool _showRightArrow = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateArrows);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateArrows();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateArrows);
    _scrollController.dispose();
    super.dispose();
  }

  void _updateArrows() {
    if (!mounted) return;
    setState(() {
      _showLeftArrow = _scrollController.hasClients && _scrollController.offset > 0;
      _showRightArrow = _scrollController.hasClients && 
          _scrollController.offset < _scrollController.position.maxScrollExtent - 10;
    });
  }

  void _scrollLeft() {
    _scrollController.animateTo(
      _scrollController.offset - widget.scrollSpeed,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _scrollRight() {
    _scrollController.animateTo(
      _scrollController.offset + widget.scrollSpeed,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 850;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showTitle)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
            child: Text(
              widget.title,
              style: GoogleFonts.outfit(
                fontSize: isMobile ? 20 : 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF333333),
              ),
            ),
          ),
        const SizedBox(height: 16),
      
        if (widget.children.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            margin: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F8F8),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.inbox_outlined, size: 48, color: const Color(0xFFCCCCCC)),
                  const SizedBox(height: 12),
                  Text(
                    'No hay destinos disponibles',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: const Color(0xFF999999),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Publica tu primer destino para que aparezca aquí',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: const Color(0xFFCCCCCC),
                    ),
                  ),
                ],
              ),
            ),
          ),
        
        if (widget.children.isNotEmpty)
          Stack(
            children: [
              SizedBox(
                height: 290,
                child: ListView.separated(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
                  itemCount: widget.children.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (context, index) => widget.children[index],
                ),
              ),
              if (_showLeftArrow && !isMobile)
                Positioned(
                  left: 8,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: _scrollLeft,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFC6707),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.chevron_left,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              if (_showRightArrow && !isMobile)
                Positioned(
                  right: 8,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: _scrollRight,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFC6707),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.chevron_right,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}