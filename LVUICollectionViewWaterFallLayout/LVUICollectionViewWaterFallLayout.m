//
//  LVUICollectionViewWaterFallLayout.m
//  LVUICollectionViewWaterFallLayout
//
//  Created by lvpengwei on 16/2/9.
//  Copyright © 2016年 lvpengwei. All rights reserved.
//

#import "LVUICollectionViewWaterFallLayout.h"

@interface LVUICollectionViewWaterFallLayout ()

@property (nonatomic) CGSize contentSize;
@property (nonatomic, strong) NSArray<UICollectionViewLayoutAttributes *> *headerFrames;
@property (nonatomic, strong) NSArray<UICollectionViewLayoutAttributes *> *footerFrames;
@property (nonatomic, strong) NSArray<NSArray<UICollectionViewLayoutAttributes *> *> *itemFrames;

@end

@implementation LVUICollectionViewWaterFallLayout

- (void)prepareLayout {
    _headerFrames = nil;
    _footerFrames = nil;
    _itemFrames = nil;
    _contentSize = CGSizeZero;
    [super prepareLayout];
    if (!self.collectionView) {
        return;
    }
    if (self.collectionView.frame.size.width == 0) {
        return;
    }
    if (!self.collectionView.delegate) {
        return;
    }
    id<LVUICollectionViewWaterFallLayoutDelegate> delegate = nil;
    if ([self.collectionView.delegate conformsToProtocol:@protocol(LVUICollectionViewWaterFallLayoutDelegate)]) {
        delegate = (id<LVUICollectionViewWaterFallLayoutDelegate>)self.collectionView.delegate;
    }
    if (!delegate) {
        return;
    }
    id<UICollectionViewDataSource> dataSource = self.collectionView.dataSource;
    if (!dataSource) {
        return;
    }
    NSMutableArray *headerFrames = [NSMutableArray array];
    NSMutableArray *footerFrames = [NSMutableArray array];
    NSMutableArray *itemFrames = [NSMutableArray array];
    CGFloat x = 0, y = 0;
    NSInteger sections = [self.collectionView numberOfSections];
    for (NSInteger section = 0; section < sections; section++) {
        UIEdgeInsets sectionEdgeInsets = [delegate collectionView:self.collectionView layout:self insetForSectionAtIndex:section];
        // header
        if ([delegate respondsToSelector:@selector(collectionView:layout:referenceSizeForHeaderInSection:)]) {
            CGSize headerSize = [delegate collectionView:self.collectionView layout:self referenceSizeForHeaderInSection:section];
            if (CGSizeEqualToSize(headerSize, CGSizeZero)) {
                [headerFrames addObject:NSNull.null];
            } else {
                x = (self.collectionView.frame.size.width - sectionEdgeInsets.left - sectionEdgeInsets.right - headerSize.width) * 0.5f;
                CGRect headerFrame = CGRectMake(x, y, headerSize.width, headerSize.height);
                UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader withIndexPath:[NSIndexPath indexPathForItem:0 inSection:section]];
                attributes.frame = headerFrame;
                [headerFrames addObject:attributes];
                y += headerSize.height;
            }
        } else {
            [headerFrames addObject:NSNull.null];
        }
        y += sectionEdgeInsets.top;
        // items
        CGFloat itemSpacing = -1;
        CGFloat lineSpacing = 0;
        NSMutableArray *yArray = nil;
        if ([delegate respondsToSelector:@selector(collectionView:layout:minimumLineSpacingForSectionAtIndex:)]) {
            lineSpacing = [delegate collectionView:self.collectionView layout:self minimumLineSpacingForSectionAtIndex:section];
        }
        NSInteger items = [self.collectionView numberOfItemsInSection:section];
        NSMutableArray *itemsArray = [NSMutableArray array];
        for (NSInteger item = 0; item < items; item++) {
            CGSize itemSize = [delegate collectionView:self.collectionView layout:self sizeForItemAtIndexPath:[NSIndexPath indexPathForItem:item inSection:section]];
            if (itemSpacing < 0) {
                itemSpacing = 0;
                if ([delegate respondsToSelector:@selector(collectionView:layout:minimumInteritemSpacingForSectionAtIndex:)]) {
                    itemSpacing = [delegate collectionView:self.collectionView layout:self minimumInteritemSpacingForSectionAtIndex:section];
                }
                CGFloat contentWidth = self.collectionView.frame.size.width - sectionEdgeInsets.left - sectionEdgeInsets.right;
                // n*width+(n-1)*spacing <= contentWidth
                NSInteger num = (contentWidth + itemSpacing) / (itemSize.width + itemSpacing);
                itemSpacing = (contentWidth - itemSize.width * num) * 1.0f / (num - 1);
                yArray = [NSMutableArray array];
                for (NSInteger i = 0; i < num; i++) {
                    [yArray addObject:@0];
                }
            }
            NSInteger index = [self findLeastValueIndexInArray:yArray];
            x = sectionEdgeInsets.left + index * itemSize.width + index * itemSpacing;
            CGFloat tempY = [yArray[index] integerValue] + (item == 0 ? 0 : lineSpacing);
            CGRect frame = CGRectMake(x, y + tempY, itemSize.width, itemSize.height);
            yArray[index] = @(tempY + itemSize.height);
            UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:[NSIndexPath indexPathForItem:item inSection:section]];
            attributes.frame = frame;
            [itemsArray addObject:attributes];
            if (item == items - 1) {
                y += tempY + itemSize.height + sectionEdgeInsets.bottom;
            }
        }
        [itemFrames addObject:itemsArray];
        // footer
        if ([delegate respondsToSelector:@selector(collectionView:layout:referenceSizeForFooterInSection:)]) {
            CGSize footerSize = [delegate collectionView:self.collectionView layout:self referenceSizeForFooterInSection:section];
            if (CGSizeEqualToSize(footerSize, CGSizeZero)) {
                [footerFrames addObject:NSNull.null];
            } else {
                x = (self.collectionView.frame.size.width - sectionEdgeInsets.left - sectionEdgeInsets.right - footerSize.width) * 0.5f;
                CGRect footerFrame = CGRectMake(x, y, footerSize.width, footerSize.height);
                UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionFooter withIndexPath:[NSIndexPath indexPathForItem:0 inSection:section]];
                attributes.frame = footerFrame;
                [footerFrames addObject:attributes];
                y += footerSize.height;
            }
        } else {
            [footerFrames addObject:NSNull.null];
        }
    }
    
    _headerFrames = [headerFrames copy];
    _footerFrames = [footerFrames copy];
    _itemFrames = [itemFrames copy];
    _contentSize = CGSizeMake(self.collectionView.bounds.size.width, y);
}

- (nullable NSArray<__kindof UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSMutableArray *arr = [NSMutableArray array];
    for (UICollectionViewLayoutAttributes *attributes in self.headerFrames) {
        if ([attributes isKindOfClass:[UICollectionViewLayoutAttributes class]]) {
            if (CGRectIntersectsRect(rect, attributes.frame)) {
                [arr addObject:attributes];
            }
        }
    }
    for (UICollectionViewLayoutAttributes *attributes in self.footerFrames) {
        if ([attributes isKindOfClass:[UICollectionViewLayoutAttributes class]]) {
            if (CGRectIntersectsRect(rect, attributes.frame)) {
                [arr addObject:attributes];
            }
        }
    }
    for (NSArray *tempArr in self.itemFrames) {
        for (UICollectionViewLayoutAttributes *attributes in tempArr) {
            if (CGRectIntersectsRect(rect, attributes.frame)) {
                [arr addObject:attributes];
            }
        }
    }
    return arr;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section < _itemFrames.count) {
        NSArray *arr = _itemFrames[indexPath.section];
        if (indexPath.item < arr.count) {
            return arr[indexPath.item];
        }
    }
    return nil;
}

- (nullable UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath {
    NSArray *arr = nil;
    if ([elementKind isEqualToString:UICollectionElementKindSectionHeader]) {
        arr = _headerFrames;
    } else if ([elementKind isEqualToString:UICollectionElementKindSectionFooter]) {
        arr = _footerFrames;
    }
    if (arr.count) {
        if (indexPath.section < arr.count) {
            UICollectionViewLayoutAttributes *attributes = arr[indexPath.section];
            if ([attributes isKindOfClass:[UICollectionViewLayoutAttributes class]]) {
                return attributes;
            }
        }
    }
    return nil;
}

- (CGSize)collectionViewContentSize {
    return self.contentSize;
}

#pragma mark - Util

- (NSInteger)findLeastValueIndexInArray:(NSArray *)array {
    if (array.count == 1) {
        return 0;
    }
    NSInteger index = 0;
    NSInteger minValue = [array[0] integerValue];
    for (NSInteger i = 1; i < array.count; i++) {
        if ([array[i] integerValue] < minValue) {
            index = i;
            minValue = [array[i] integerValue];
        }
    }
    return index;
}

@end
