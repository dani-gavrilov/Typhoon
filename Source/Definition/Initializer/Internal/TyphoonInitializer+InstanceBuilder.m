////////////////////////////////////////////////////////////////////////////////
//
//  TYPHOON FRAMEWORK
//  Copyright 2013, Jasper Blues & Contributors
//  All Rights Reserved.
//
//  NOTICE: The authors permit you to use, modify, and distribute this file
//  in accordance with the terms of the license agreement accompanying it.
//
////////////////////////////////////////////////////////////////////////////////



#import "TyphoonLinkerCategoryBugFix.h"
#import "TyphoonInitializer+InstanceBuilder.h"
#import "TyphoonParameterInjectedWithStringRepresentation.h"
#import "TyphoonDefinition.h"
#import "TyphoonDefinition+InstanceBuilder.h"

TYPHOON_LINK_CATEGORY(TyphoonInitializer_InstanceBuilder)


@implementation TyphoonInitializer (InstanceBuilder)

/* ====================================================================================================================================== */
#pragma mark - Interface Methods

- (NSArray*)parametersInjectedByValue
{
    NSPredicate* predicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary* bindings)
    {
        return [evaluatedObject isKindOfClass:[TyphoonParameterInjectedWithStringRepresentation class]];
    }];
    return [_injectedParameters filteredArrayUsingPredicate:predicate];

}

- (NSInvocation*)newInvocation
{
    Class clazz = [_definition type];

    if ([clazz respondsToSelector:_selector] == NO && [clazz instancesRespondToSelector:_selector] == NO)
    {
        NSString* typeType = self.isClassMethod ? @"Class" : @"Instance";
        [NSException raise:NSInvalidArgumentException
            format:@"%@ method '%@' not found on '%@'. Did you include the required ':' characters to signify arguments?", typeType,
                   NSStringFromSelector(_selector), NSStringFromClass(clazz)];
    }

    NSInvocation* invocation;
    if (self.isClassMethod)
    {
        invocation = [NSInvocation invocationWithMethodSignature:[clazz methodSignatureForSelector:_selector]];
    }
    else
    {
        invocation = [NSInvocation invocationWithMethodSignature:[clazz instanceMethodSignatureForSelector:_selector]];
    }
    [invocation setSelector:_selector];
    return invocation;
}


- (void)setComponentDefinition:(TyphoonDefinition*)definition
{
    _definition = definition;
    [self resolveIsClassMethod];
}

- (BOOL)isClassMethod
{
    return [self resolveIsClassMethod];
}


/* ====================================================================================================================================== */
#pragma mark - Private Methods

- (BOOL)resolveIsClassMethod
{
    if (_definition.factoryReference)
    {
        if (_isClassMethodStrategy == TyphoonComponentInitializerIsClassMethodYes)
        {
            [NSException raise:NSInvalidArgumentException
                format:@"'is-class-method' can't be 'TyphoonComponentInitializerIsClassMethodYes' when factory-component is used!"];
        }
        else
        {
            return NO;
        }
    }

    switch (_isClassMethodStrategy)
    {
        case TyphoonComponentInitializerIsClassMethodNo:
            return NO;
        case TyphoonComponentInitializerIsClassMethodYes:
            return YES;
        case TyphoonComponentInitializerIsClassMethodGuess:
            return [self selectorDoesNotStartWithInit];
        default:
            return NO;
    }
}

- (BOOL)selectorDoesNotStartWithInit
{
    return ![NSStringFromSelector(_selector) hasPrefix:@"init"];
}


@end
