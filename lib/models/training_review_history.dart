import 'training.dart';
import 'training_session_progress.dart';

List<TrainingAttemptReview> trainingAttemptReviews(
  Iterable<RoundAttemptReview> reviews,
) => reviews
    .map(
      (review) => TrainingAttemptReview(
        taskNumber: review.taskNumber,
        taskKey: review.taskKey,
        prompt: review.prompt,
        correctAnswer: review.correctAnswer,
        firstAnswer: review.firstAnswer,
        wrongAnswerAttempts: review.wrongAnswerAttempts,
        usedHelp: review.usedHelp,
        checkpointQuestion: review.checkpointAttempt?.question,
        checkpointFirstAnswer: review.checkpointAttempt?.firstAnswer,
        checkpointCorrectAnswer: review.checkpointAttempt?.correctAnswer,
      ),
    )
    .toList(growable: false);
