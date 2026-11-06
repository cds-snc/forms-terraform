import { EitherAsync, Left, Right } from "purify-ts";

export const EitherAsyncUtils = {
  right: <R = void>(value?: R): EitherAsync<never, R> => EitherAsync.liftEither(Right(value as R)),

  left: <L>(value: L): EitherAsync<L, never> => EitherAsync.liftEither(Left(value)),

  rightOnLeft: <L, R = void>(operation: EitherAsync<L, R>, onLeft?: { fallbackValue?: R; sideEffect?: (value: L) => void }): EitherAsync<never, R> =>
    operation.ifLeft((leftValue) => onLeft?.sideEffect?.(leftValue)).chainLeft(() => EitherAsyncUtils.right(onLeft?.fallbackValue as R)),

  ifRightAsync:
    <E, A, B>(fn: (value: A) => EitherAsync<E, B>): ((value: A) => EitherAsync<E, A>) =>
    (value) =>
      fn(value).map(() => value),
};
