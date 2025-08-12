#pragma once

#ifdef __OBJC__
#import <Foundation/Foundation.h>
#endif

namespace mdviewer {

class Document;

#ifdef __OBJC__
NSAttributedString* renderMarkdownDocument(const Document* doc, bool isDarkMode);
#endif

} // namespace mdviewer