import { EitherAsync, Left, Right } from "purify-ts";

export const EitherAsyncUtils = {
  right: <R>(value: R): EitherAsync<never, R> => EitherAsync.liftEither(Right(value)),

  rightVoid: (): EitherAsync<never, void> => EitherAsync.liftEither(Right(undefined)),

  left: <L>(value: L): EitherAsync<L, never> => EitherAsync.liftEither(Left(value)),

  rightOnLeft: <L, OpR, FbR>(operation: EitherAsync<L, OpR>, fallbackValue: FbR, sideEffect?: (value: L) => void): EitherAsync<never, OpR | FbR> =>
    operation.ifLeft((leftValue) => sideEffect?.(leftValue)).chainLeft(() => EitherAsyncUtils.right(fallbackValue)),

  // biome-ignore lint/suspicious/noConfusingVoidType: The void type represents the intentional absence of a fallback value when recovering from a Left
  rightVoidOnLeft: <L, R>(operation: EitherAsync<L, R>, sideEffect?: (value: L) => void): EitherAsync<never, R | void> =>
    operation.ifLeft((leftValue) => sideEffect?.(leftValue)).chainLeft(() => EitherAsyncUtils.rightVoid()),

  ifRightAsync:
    <E, A, B>(fn: (value: A) => EitherAsync<E, B>): ((value: A) => EitherAsync<E, A>) =>
    (value) =>
      fn(value).map(() => value),
};
