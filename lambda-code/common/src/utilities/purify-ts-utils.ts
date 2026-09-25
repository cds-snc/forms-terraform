import { EitherAsync, Left, Right } from "purify-ts";

export const EitherAsyncUtils = {
  rightWithValue: <R>(value: R): EitherAsync<never, R> => EitherAsync.liftEither(Right(value)),

  right: (): EitherAsync<never, void> => EitherAsync.liftEither(Right(undefined)),

  rightOnLeftWithValue: <L, R>(operation: EitherAsync<L, R>, returnedValue: R, onLeft?: (value: L) => void): EitherAsync<never, R> =>
    operation.chainLeft((leftValue) => {
      onLeft?.(leftValue);
      return EitherAsyncUtils.rightWithValue(returnedValue);
    }),

  rightOnLeft: <L>(operation: EitherAsync<L, void>, onLeft?: (value: L) => void): EitherAsync<never, void> =>
    operation.chainLeft((leftValue) => {
      onLeft?.(leftValue);
      return EitherAsyncUtils.right();
    }),

  left: <L>(value: L): EitherAsync<L, never> => EitherAsync.liftEither(Left(value)),
};
