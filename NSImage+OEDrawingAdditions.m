/*
 Copyright (c) 2011, OpenEmu Team

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
     * Redistributions of source code must retain the above copyright
       notice, this list of conditions and the following disclaimer.
     * Redistributions in binary form must reproduce the above copyright
       notice, this list of conditions and the following disclaimer in the
       documentation and/or other materials provided with the distribution.
     * Neither the name of the OpenEmu Team nor the
       names of its contributors may be used to endorse or promote products
       derived from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY OpenEmu Team ''AS IS'' AND ANY
 EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL OpenEmu Team BE LIABLE FOR ANY
 DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "NSImage+OEDrawingAdditions.h"

@interface OENSThreePartImage : NSImage

- (id)initWithImageParts:(NSArray *)imageParts vertical:(BOOL)vertical;

@property(nonatomic, readonly, retain) NSArray *parts;
@property(nonatomic, readonly, getter = isVertical) BOOL vertical;

@end

@interface OENSNinePartImage : NSImage

- (id)initWithImageParts:(NSArray *)imageParts;

@property(nonatomic, readonly, retain) NSArray *parts;

@end

@implementation NSImage (OEDrawingAdditions)

- (void)drawInRect:(NSRect)targetRect fromRect:(NSRect)sourceRect operation:(NSCompositingOperation)op fraction:(CGFloat)frac respectFlipped:(BOOL)flipped hints:(NSDictionary *)hints leftBorder:(float)leftBorder rightBorder:(float)rightBorder topBorder:(float)topBorder bottomBorder:(float)bottomBorder{

    if(NSEqualRects(sourceRect, NSZeroRect)) sourceRect=NSMakeRect(0, 0, [self size].width, [self size].height);

    NSRect workingSourceRect;
    NSRect workingTargetRect;

    BOOL sourceFlipped = [self isFlipped];
    BOOL targetFlipped = [[NSGraphicsContext currentContext] isFlipped];

    NSDictionary *drawingHints = hints;
    if(!drawingHints)
        drawingHints = NoInterpol;

    // Bottom Left
    if(sourceFlipped)
    {
        workingSourceRect = NSMakeRect(sourceRect.origin.x, sourceRect.origin.y+sourceRect.size.height-bottomBorder, leftBorder, bottomBorder);
    } else
    {
        workingSourceRect = NSMakeRect(sourceRect.origin.x, sourceRect.origin.y, leftBorder, bottomBorder);
    }

    if(targetFlipped)
    {
        workingTargetRect = NSMakeRect(targetRect.origin.x, targetRect.origin.y+targetRect.size.height-bottomBorder, leftBorder, bottomBorder);
    }
    else
    {
        workingTargetRect = NSMakeRect(targetRect.origin.x, targetRect.origin.y, leftBorder, bottomBorder);
    }
    [self drawInRect:workingTargetRect fromRect:workingSourceRect operation:op fraction:frac respectFlipped:flipped hints:drawingHints];

    // Bottom Center
    if(sourceFlipped)
    {
        workingSourceRect = NSMakeRect(sourceRect.origin.x+leftBorder, sourceRect.origin.y+sourceRect.size.height-bottomBorder, sourceRect.size.width-leftBorder-rightBorder, bottomBorder);
    }
    else
    {
        workingSourceRect = NSMakeRect(sourceRect.origin.x+leftBorder, sourceRect.origin.y, sourceRect.size.width-leftBorder-rightBorder, bottomBorder);
    }

    if(targetFlipped)
    {
        workingTargetRect = NSMakeRect(targetRect.origin.x+leftBorder, targetRect.origin.y+targetRect.size.height-bottomBorder, targetRect.size.width-leftBorder-rightBorder, bottomBorder);
    }
    else
    {
        workingTargetRect = NSMakeRect(targetRect.origin.x+leftBorder, targetRect.origin.y, targetRect.size.width-leftBorder-rightBorder, bottomBorder);
    }
    [self drawInRect:workingTargetRect fromRect:workingSourceRect operation:op fraction:frac respectFlipped:flipped hints:drawingHints];

    // Bottom Right
    if(sourceFlipped)
    {
        workingSourceRect = NSMakeRect(sourceRect.origin.x+sourceRect.size.width-rightBorder, sourceRect.origin.y+sourceRect.size.height-bottomBorder, rightBorder, bottomBorder);
    }
    else
    {
        workingSourceRect = NSMakeRect(sourceRect.origin.x+sourceRect.size.width-rightBorder, sourceRect.origin.y, rightBorder, bottomBorder);
    }

    if(targetFlipped)
    {
        workingTargetRect = NSMakeRect(targetRect.origin.x+targetRect.size.width-rightBorder, targetRect.origin.y+targetRect.size.height-bottomBorder, rightBorder, bottomBorder);
    }
    else
    {
        workingTargetRect = NSMakeRect(targetRect.origin.x+targetRect.size.width-rightBorder, targetRect.origin.y, rightBorder, bottomBorder);
    }
    [self drawInRect:workingTargetRect fromRect:workingSourceRect operation:op fraction:frac respectFlipped:flipped hints:drawingHints];


    // Center Left
    if(sourceFlipped)
    {
        workingSourceRect = NSMakeRect(sourceRect.origin.x, sourceRect.origin.y+topBorder, leftBorder, sourceRect.size.height-topBorder-bottomBorder);
    }
    else
    {
        workingSourceRect = NSMakeRect(sourceRect.origin.x, sourceRect.origin.y+bottomBorder, leftBorder, sourceRect.size.height-topBorder-bottomBorder);
    }

    if(targetFlipped)
    {
        workingTargetRect = NSMakeRect(targetRect.origin.x, targetRect.origin.y+topBorder, leftBorder, targetRect.size.height-topBorder-bottomBorder);
    }
    else
    {
        workingTargetRect = NSMakeRect(targetRect.origin.x, targetRect.origin.y+bottomBorder, leftBorder, targetRect.size.height-topBorder-bottomBorder);
    }
    [self drawInRect:workingTargetRect fromRect:workingSourceRect operation:op fraction:frac respectFlipped:flipped hints:drawingHints];


    // Center Center
    if(sourceFlipped)
    {
        workingSourceRect = NSMakeRect(sourceRect.origin.x+leftBorder, sourceRect.origin.y+topBorder, sourceRect.size.width-rightBorder-leftBorder, sourceRect.size.height-topBorder-bottomBorder);
    }
    else
    {
        workingSourceRect = NSMakeRect(sourceRect.origin.x+leftBorder, sourceRect.origin.y+bottomBorder, sourceRect.size.width-rightBorder-leftBorder, sourceRect.size.height-topBorder-bottomBorder);
    }

    if(targetFlipped)
    {
        workingTargetRect = NSMakeRect(targetRect.origin.x+leftBorder, targetRect.origin.y+topBorder, targetRect.size.width-leftBorder-rightBorder, targetRect.size.height-topBorder-bottomBorder);
    }
    else
    {
        workingTargetRect = NSMakeRect(targetRect.origin.x+leftBorder, targetRect.origin.y+bottomBorder, targetRect.size.width-leftBorder-rightBorder, targetRect.size.height-topBorder-bottomBorder);
    }
    [self drawInRect:workingTargetRect fromRect:workingSourceRect operation:op fraction:frac respectFlipped:flipped hints:drawingHints];


    // Center Right
    if(sourceFlipped)
    {
        workingSourceRect = NSMakeRect(sourceRect.origin.x+sourceRect.size.width-rightBorder, sourceRect.origin.y+topBorder, rightBorder, sourceRect.size.height-topBorder-bottomBorder);
    }
    else
    {
        workingSourceRect = NSMakeRect(sourceRect.origin.x+sourceRect.size.width-rightBorder, sourceRect.origin.y+bottomBorder, rightBorder, sourceRect.size.height-topBorder-bottomBorder);
    }

    if(targetFlipped)
    {
        workingTargetRect = NSMakeRect(targetRect.origin.x+targetRect.size.width-rightBorder, targetRect.origin.y+topBorder, rightBorder, targetRect.size.height-topBorder-bottomBorder);
    }
    else
    {
        workingTargetRect = NSMakeRect(targetRect.origin.x+targetRect.size.width-rightBorder, targetRect.origin.y+bottomBorder, rightBorder, targetRect.size.height-topBorder-bottomBorder);
    }
    [self drawInRect:workingTargetRect fromRect:workingSourceRect operation:op fraction:frac respectFlipped:flipped hints:drawingHints];


    // Top Left
    if(sourceFlipped)
    {
        workingSourceRect = NSMakeRect(sourceRect.origin.x, sourceRect.origin.y, leftBorder, topBorder);
    }
    else
    {
        workingSourceRect = NSMakeRect(sourceRect.origin.x, sourceRect.origin.y+sourceRect.size.height-topBorder, leftBorder, topBorder);
    }

    if(targetFlipped)
    {
        workingTargetRect = NSMakeRect(targetRect.origin.x, targetRect.origin.y, leftBorder, topBorder);
    }
    else
    {
        workingTargetRect = NSMakeRect(targetRect.origin.x, targetRect.origin.y+targetRect.size.height-topBorder, leftBorder, topBorder);
    }
    [self drawInRect:workingTargetRect fromRect:workingSourceRect operation:op fraction:frac respectFlipped:flipped hints:drawingHints];

    // Top Center
    if(sourceFlipped)
    {
        workingSourceRect = NSMakeRect(sourceRect.origin.x+leftBorder, sourceRect.origin.y, sourceRect.size.width-rightBorder-leftBorder, topBorder);
    }
    else
    {
        workingSourceRect = NSMakeRect(sourceRect.origin.x+leftBorder, sourceRect.origin.y+sourceRect.size.height-topBorder, sourceRect.size.width-rightBorder-leftBorder, topBorder);
    }

    if(targetFlipped)
    {
        workingTargetRect = NSMakeRect(targetRect.origin.x+leftBorder, targetRect.origin.y, targetRect.size.width-leftBorder-rightBorder, topBorder);
    }
    else
    {
        workingTargetRect = NSMakeRect(targetRect.origin.x+leftBorder, targetRect.origin.y+targetRect.size.height-topBorder, targetRect.size.width-leftBorder-rightBorder, topBorder);
    }
    [self drawInRect:workingTargetRect fromRect:workingSourceRect operation:op fraction:frac respectFlipped:flipped hints:drawingHints];

    // Top Right
    if(sourceFlipped)
    {
        workingSourceRect = NSMakeRect(sourceRect.origin.x+sourceRect.size.width-rightBorder, sourceRect.origin.y, rightBorder, topBorder);
    }
    else
    {
        workingSourceRect = NSMakeRect(sourceRect.origin.x+sourceRect.size.width-rightBorder, sourceRect.origin.y+sourceRect.size.height-topBorder, rightBorder, topBorder);
    }

    if(targetFlipped)
    {
        workingTargetRect = NSMakeRect(targetRect.origin.x+targetRect.size.width-rightBorder, targetRect.origin.y, rightBorder, topBorder);
    }
    else
    {
        workingTargetRect = NSMakeRect(targetRect.origin.x+targetRect.size.width-rightBorder, targetRect.origin.y+targetRect.size.height-topBorder, rightBorder, topBorder);
    }
    [self drawInRect:workingTargetRect fromRect:workingSourceRect operation:op fraction:frac respectFlipped:flipped hints:drawingHints];
}

- (NSImage *)subImageFromRect:(NSRect)rect
{
    NSImage *newImage = [[NSImage alloc] initWithSize:rect.size];

    [newImage lockFocusFlipped:YES];
    [self drawInRect:NSMakeRect(0, 0, rect.size.width, rect.size.height) fromRect:rect operation:NSCompositeCopy fraction:1.0];
    [newImage unlockFocus];

    return newImage;
}

- (void)setName:(NSString *)name forSubimageInRect:(NSRect)aRect
{
    static NSMutableArray *interfaceImages;
    if(!interfaceImages) interfaceImages = [[NSMutableArray alloc] init];

    NSImage *resultImage = [self subImageFromRect:aRect];
    [resultImage setName:name];

    [interfaceImages addObject:resultImage];
}

- (NSImage *)imageFromParts:(NSArray *)parts vertical:(BOOL)vertical;
{
    if(parts == nil || [parts count] == 0) return self;

    const NSSize    size       = [self size];
    NSMutableArray *imageParts = [NSMutableArray arrayWithCapacity:[parts count]];
    NSUInteger      count      = 0;

    NSRect rect;
    id     part;

    if([parts count] >= 9)      count = 9;
    else if([parts count] >= 3) count = 3;
    else if([parts count] >= 1) count = 1;

    for(NSUInteger i = 0; i < count; i++)
    {
        rect = NSZeroRect;
        part = [parts objectAtIndex:i];

        if([part isKindOfClass:[NSString class]])     rect = NSRectFromString(part);
        else if([part isKindOfClass:[NSValue class]]) rect = [part rectValue];
        else                                          NSLog(@"Unable to parse NSRect from part: %@", part);

        // Flip coordinate system (if it is not already flipped)
        if(!NSIsEmptyRect(rect))
        {
            if(![self isFlipped]) rect.origin.y = size.height - rect.origin.y - rect.size.height;
            [imageParts addObject:[self subImageFromRect:rect]];
        }
        else
        {
            [imageParts addObject:[NSNull null]];
        }
    }

    NSImage *result = nil;
    if(count == 1)      result = [imageParts lastObject];
    else if(count == 3) result = [[OENSThreePartImage alloc] initWithImageParts:imageParts vertical:vertical];
    else if(count == 9) result = [[OENSNinePartImage alloc] initWithImageParts:imageParts];

    return result;
}

@end

@implementation OENSThreePartImage

@synthesize parts = _parts;
@synthesize vertical = _vertical;

- (id)initWithImageParts:(NSArray *)imageParts vertical:(BOOL)vertical
{
    if((self = [super init]))
    {
        _parts = [imageParts copy];
        _vertical = vertical;
    }

    return self;
}

- (void)drawInRect:(NSRect)rect fromRect:(NSRect)fromRect operation:(NSCompositingOperation)op fraction:(CGFloat)delta
{
    [self drawInRect:rect fromRect:fromRect operation:op fraction:delta respectFlipped:NO hints:nil];
}

- (void)drawInRect:(NSRect)dstSpacePortionRect fromRect:(NSRect)srcSpacePortionRect operation:(NSCompositingOperation)op fraction:(CGFloat)requestedAlpha respectFlipped:(BOOL)respectContextIsFlipped hints:(NSDictionary *)hints
{
    NSImage *startCap   = ([_parts objectAtIndex:0] == [NSNull null] ? nil : [_parts objectAtIndex:0]);
    NSImage *centerFill = ([_parts objectAtIndex:1] == [NSNull null] ? nil : [_parts objectAtIndex:1]);
    NSImage *endCap     = ([_parts objectAtIndex:2] == [NSNull null] ? nil : [_parts objectAtIndex:2]);

    NSDrawThreePartImage(dstSpacePortionRect, startCap, centerFill, endCap, _vertical, op, requestedAlpha, respectContextIsFlipped);
}

@end

@implementation OENSNinePartImage

@synthesize parts = _parts;

- (id)initWithImageParts:(NSArray *)imageParts
{
    if((self = [super init]))
    {
        _parts = [imageParts copy];
    }

    return self;
}


- (void)drawInRect:(NSRect)rect fromRect:(NSRect)fromRect operation:(NSCompositingOperation)op fraction:(CGFloat)delta
{
    [self drawInRect:rect fromRect:fromRect operation:op fraction:delta respectFlipped:NO hints:nil];
}

- (void)drawInRect:(NSRect)dstSpacePortionRect fromRect:(NSRect)srcSpacePortionRect operation:(NSCompositingOperation)op fraction:(CGFloat)requestedAlpha respectFlipped:(BOOL)respectContextIsFlipped hints:(NSDictionary *)hints
{
    NSImage *topLeftCorner     = ([_parts objectAtIndex:0] == [NSNull null] ? nil : [_parts objectAtIndex:0]);
    NSImage *topEdgeFill       = ([_parts objectAtIndex:1] == [NSNull null] ? nil : [_parts objectAtIndex:1]);
    NSImage *topRightCorner    = ([_parts objectAtIndex:2] == [NSNull null] ? nil : [_parts objectAtIndex:2]);
    NSImage *leftEdgeFill      = ([_parts objectAtIndex:3] == [NSNull null] ? nil : [_parts objectAtIndex:3]);
    NSImage *centerFill        = ([_parts objectAtIndex:4] == [NSNull null] ? nil : [_parts objectAtIndex:4]);
    NSImage *rightEdgeFill     = ([_parts objectAtIndex:5] == [NSNull null] ? nil : [_parts objectAtIndex:5]);
    NSImage *bottomLeftCorner  = ([_parts objectAtIndex:6] == [NSNull null] ? nil : [_parts objectAtIndex:6]);
    NSImage *bottomEdgeFill    = ([_parts objectAtIndex:7] == [NSNull null] ? nil : [_parts objectAtIndex:7]);
    NSImage *bottomRightCorner = ([_parts objectAtIndex:8] == [NSNull null] ? nil : [_parts objectAtIndex:8]);

    NSDrawNinePartImage(dstSpacePortionRect, topLeftCorner, topEdgeFill, topRightCorner, leftEdgeFill, centerFill, rightEdgeFill, bottomLeftCorner, bottomEdgeFill, bottomRightCorner, op, requestedAlpha, respectContextIsFlipped);
}

@end
