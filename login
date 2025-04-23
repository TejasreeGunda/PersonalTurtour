from datetime import datetime
from app import db
from flask_login import UserMixin
import json

class User(UserMixin, db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(64), unique=True, nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)
    password_hash = db.Column(db.String(256), nullable=False)
    date_registered = db.Column(db.DateTime, default=datetime.utcnow)
    
    # Learning profile
    programming_experience = db.Column(db.String(50), default="Beginner")  # Beginner, Intermediate, Advanced
    known_languages = db.Column(db.Text, default="[]")  # JSON list of languages
    target_languages = db.Column(db.Text, default="[]")  # JSON list of languages
    learning_goals = db.Column(db.Text, default="[]")  # JSON list of goals
    exam_goals = db.Column(db.Text, default="[]")  # JSON list of target exams
    
    # User progress
    progress = db.relationship('UserProgress', backref='user', lazy=True)
    exam_attempts = db.relationship('ExamAttempt', backref='user', lazy=True)
    
    def get_known_languages(self):
        return json.loads(self.known_languages)
    
    def get_target_languages(self):
        return json.loads(self.target_languages)
    
    def get_learning_goals(self):
        return json.loads(self.learning_goals)
    
    def get_exam_goals(self):
        return json.loads(self.exam_goals)
    
    def set_known_languages(self, languages):
        self.known_languages = json.dumps(languages)
    
    def set_target_languages(self, languages):
        self.target_languages = json.dumps(languages)
    
    def set_learning_goals(self, goals):
        self.learning_goals = json.dumps(goals)
    
    def set_exam_goals(self, exams):
        self.exam_goals = json.dumps(exams)


class ProgrammingContent(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(200), nullable=False)
    description = db.Column(db.Text, nullable=False)
    content = db.Column(db.Text, nullable=False)  # HTML/Markdown content
    programming_language = db.Column(db.String(50), nullable=False)  # Python, JavaScript, etc.
    difficulty_level = db.Column(db.String(20), nullable=False)  # Beginner, Intermediate, Advanced
    content_type = db.Column(db.String(20), nullable=False)  # Tutorial, Exercise, Reference
    keywords = db.Column(db.Text, nullable=False)  # JSON list of keywords
    date_created = db.Column(db.DateTime, default=datetime.utcnow)
    date_updated = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Related content
    related_content = db.relationship(
        'RelatedContent',
        foreign_keys='RelatedContent.content_id',
        backref='main_content',
        lazy=True
    )
    
    # User progress for this content
    progress = db.relationship('UserProgress', backref='content', lazy=True)
    
    def get_keywords(self):
        return json.loads(self.keywords)
    
    def set_keywords(self, keywords):
        self.keywords = json.dumps(keywords)


class RelatedContent(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    content_id = db.Column(db.Integer, db.ForeignKey('programming_content.id'), nullable=False)
    related_id = db.Column(db.Integer, db.ForeignKey('programming_content.id'), nullable=False)
    relationship_type = db.Column(db.String(20), nullable=False)  # Prerequisite, Followup, Related
    
    related_to = db.relationship('ProgrammingContent', foreign_keys=[related_id], backref='related_from', lazy=True)


class UserProgress(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    content_id = db.Column(db.Integer, db.ForeignKey('programming_content.id'), nullable=False)
    status = db.Column(db.String(20), nullable=False, default='Not Started')  # Not Started, In Progress, Completed
    progress_percentage = db.Column(db.Integer, default=0)  # 0-100
    last_accessed = db.Column(db.DateTime, default=datetime.utcnow)
    completed_date = db.Column(db.DateTime, nullable=True)
    notes = db.Column(db.Text, nullable=True)


class Exam(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(200), nullable=False)
    description = db.Column(db.Text, nullable=False)
    programming_language = db.Column(db.String(50), nullable=False)
    difficulty_level = db.Column(db.String(20), nullable=False)
    time_limit_minutes = db.Column(db.Integer, nullable=False)
    passing_percentage = db.Column(db.Integer, nullable=False, default=70)
    
    # Questions for this exam
    questions = db.relationship('ExamQuestion', backref='exam', lazy=True)
    
    # User attempts
    attempts = db.relationship('ExamAttempt', backref='exam', lazy=True)


class ExamQuestion(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    exam_id = db.Column(db.Integer, db.ForeignKey('exam.id'), nullable=False)
    question_text = db.Column(db.Text, nullable=False)
    question_type = db.Column(db.String(20), nullable=False)  # Multiple Choice, Coding, Short Answer
    options = db.Column(db.Text, nullable=True)  # JSON list of options for multiple choice
    correct_answer = db.Column(db.Text, nullable=False)
    points = db.Column(db.Integer, nullable=False, default=1)
    
    def get_options(self):
        if self.options:
            return json.loads(self.options)
        return []
    
    def set_options(self, options_list):
        self.options = json.dumps(options_list)


class ExamAttempt(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    exam_id = db.Column(db.Integer, db.ForeignKey('exam.id'), nullable=False)
    start_time = db.Column(db.DateTime, default=datetime.utcnow)
    end_time = db.Column(db.DateTime, nullable=True)
    score = db.Column(db.Integer, nullable=True)
    max_score = db.Column(db.Integer, nullable=True)
    passed = db.Column(db.Boolean, nullable=True)
    
    # Answers for this attempt
    answers = db.relationship('ExamAnswer', backref='attempt', lazy=True)


class ExamAnswer(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    attempt_id = db.Column(db.Integer, db.ForeignKey('exam_attempt.id'), nullable=False)
    question_id = db.Column(db.Integer, db.ForeignKey('exam_question.id'), nullable=False)
    user_answer = db.Column(db.Text, nullable=False)
    is_correct = db.Column(db.Boolean, nullable=False)
    points_awarded = db.Column(db.Integer, nullable=False, default=0)
    
    # Link to the question
    question = db.relationship('ExamQuestion', backref='answers', lazy=True)


# Seed data for programming languages
programming_languages = [
    "Python", "JavaScript", "Java", "C#", "C++", "PHP", "Ruby", "Swift", "Go", "Kotlin", "TypeScript", "SQL", "Rust"
]
