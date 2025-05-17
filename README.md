# ml-intelligent-medical-chat-with-appointment-booking-location-mapping-and-mail

from flask import Flask, render_template, request, jsonify, session, redirect, url_for, flash
from flask_sqlalchemy import SQLAlchemy
from flask_bcrypt import Bcrypt
from flask_cors import CORS
import os
from datetime import datetime
import json
from connect_mysql import create_connection
from flask_migrate import Migrate
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import logging
from flask import Flask, send_from_directory
from flask import send_file
from PIL import Image
import io


# Initialize Flask app
app = Flask(__name__)

@app.route('/manage_requests')
def manage_requests():
    return render_template('manage_requests.html')  # Or whatever is appropriate


@app.route('/favicon.ico')
def favicon():
    return send_from_directory(os.path.join(app.root_path, 'static'),
                               'favicon.ico', mimetype='image/vnd.microsoft.icon')
# Set up logging
logging.basicConfig(filename='email_log.txt', level=logging.INFO, format='%(asctime)s - %(message)s')

@app.route('/api/placeholder/<int:width>/<int:height>')
def placeholder(width, height):
    img = Image.new('RGB', (width, height), color=(200, 200, 200))
    buf = io.BytesIO()
    img.save(buf, format='PNG')
    buf.seek(0)
    return send_file(buf, mimetype='image/png')

# ✅ Email function
def send_email(to_email, subject, body):
    smtp_server = 'smtp.gmail.com'
    smtp_port = 587
    sender_email = 'raghavendrakraghu557@gmail.com'
    sender_password = 'tqpo rxdl ykgg fozu'  # Use an App Password from Gmail

    msg = MIMEMultipart()
    msg['From'] = sender_email
    msg['To'] = to_email
    msg['Subject'] = subject

    msg.attach(MIMEText(body, 'plain'))

    try:
        with smtplib.SMTP(smtp_server, smtp_port) as server:
            server.starttls()
            server.login(sender_email, sender_password)
            server.send_message(msg)
        logging.info(f"Email sent successfully to {to_email}. Subject: {subject}")  # Log successful send
        return True
    except Exception as e:
        logging.error(f"Failed to send email to {to_email}. Error: {str(e)}")  # Log failure
        return False

@app.route('/send-email', methods=['POST'])
def email_route():
    data = request.json
    to_email = data.get('to')
    subject = data.get('subject')
    body = data.get('body')

    if send_email(to_email, subject, body):
        return jsonify({'status': 'Email sent successfully!'})
    else:
        return jsonify({'status': 'Failed to send email'}), 500

app.secret_key = os.urandom(24)  # For session management
app.config['SQLALCHEMY_DATABASE_URI'] = 'mysql://root:@localhost:3306/chatbot'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
CORS(app)  # Enable CORS for all routes

# Initialize SQLAlchemy and Bcrypt
db = SQLAlchemy(app)
bcrypt = Bcrypt(app)

# Define models based on the SQL schema
class User(db.Model):
    __tablename__ = 'users'
    user_id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    name = db.Column(db.String(100), nullable=False)
    email = db.Column(db.String(100), nullable=False, unique=True)
    password = db.Column(db.String(255), nullable=False)
    phone = db.Column(db.String(20))
    user_type = db.Column(db.Enum('patient', 'doctor'), nullable=False)
    date_registered = db.Column(db.DateTime, default=datetime.utcnow)

# Add location_id to DoctorDetail model:
#Add location_id to DoctorDetail model:
class DoctorDetail(db.Model):
    __tablename__ = 'doctor_details'
    doctor_id = db.Column(db.Integer, db.ForeignKey('users.user_id'), primary_key=True)
    doctor_name = db.Column(db.String(100), nullable=False)
    specialization = db.Column(db.String(100), nullable=False)
    qualification = db.Column(db.String(255), nullable=False)
    experience_years = db.Column(db.Integer)
    consultation_fee = db.Column(db.Float)
    location_id = db.Column(db.Integer, db.ForeignKey('hospital_location.id'))

    hospital = db.relationship('HospitalLocation', backref='doctors')

#Add HospitalLocation model:
class HospitalLocation(db.Model):
    __tablename__ = 'hospital_location'
    id = db.Column(db.Integer, primary_key=True)
    location = db.Column(db.String(255))
    hospital = db.Column(db.String(255))

    # Relationship
doctor = db.relationship('User', backref='doctor_details')

class PatientDetail(db.Model):
    __tablename__ = 'patient_details'
    patient_id = db.Column(db.Integer, db.ForeignKey('users.user_id'), primary_key=True)
    date_of_birth = db.Column(db.Date)
    gender = db.Column(db.Enum('Male', 'Female', 'Other'))
    blood_group = db.Column(db.String(10))
    allergies = db.Column(db.Text)
    chronic_conditions = db.Column(db.Text)
    
    # Relationship
    patient = db.relationship('User', backref='patient_details')

class Appointment(db.Model):
    __tablename__ = 'appointments'
    appointment_id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    patient_id = db.Column(db.Integer, db.ForeignKey('users.user_id'), nullable=False)
    doctor_id = db.Column(db.Integer, db.ForeignKey('users.user_id'), nullable=False)
    appointment_date = db.Column(db.Date, nullable=False)
    appointment_time = db.Column(db.Time, nullable=False)
    reason = db.Column(db.Text, nullable=False)
    status = db.Column(db.Enum('Pending', 'Confirmed', 'Completed', 'Cancelled'), default='Pending')
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    patient = db.relationship('User', foreign_keys=[patient_id], backref='appointments_as_patient')
    doctor = db.relationship('User', foreign_keys=[doctor_id], backref='appointments_as_doctor')

class ChatMessage(db.Model):
    __tablename__ = 'chat_messages'
    message_id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.user_id'), nullable=False)
    message_text = db.Column(db.Text, nullable=False)
    is_bot_message = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    # Relationship
    user = db.relationship('User', backref='chat_messages')

class MedicalRecord(db.Model):
    __tablename__ = 'medical_records'
    record_id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    patient_id = db.Column(db.Integer, db.ForeignKey('users.user_id'), nullable=False)
    doctor_id = db.Column(db.Integer, db.ForeignKey('users.user_id'), nullable=False)
    appointment_id = db.Column(db.Integer, db.ForeignKey('appointments.appointment_id'))
    diagnosis = db.Column(db.Text, nullable=False)
    prescription = db.Column(db.Text)
    notes = db.Column(db.Text)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    # Relationships
    patient = db.relationship('User', foreign_keys=[patient_id], backref='medical_records_as_patient')
    doctor = db.relationship('User', foreign_keys=[doctor_id], backref='medical_records_as_doctor')
    appointment = db.relationship('Appointment', backref='medical_record')

class ContactMessage(db.Model):
    __tablename__ = 'contact_messages'
    message_id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    name = db.Column(db.String(100), nullable=False)
    email = db.Column(db.String(100), nullable=False)
    subject = db.Column(db.String(255), nullable=False)
    message = db.Column(db.Text, nullable=False)
    status = db.Column(db.Enum('Unread', 'Read', 'Responded'), default='Unread')
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

# Simple AI response generator
def generate_ai_response(message):
    message = message.lower()
    
    # Simple pattern matching for responses
    if 'headache' in message:
        return "Headaches can be caused by various factors including stress, dehydration, or eye strain. If it's persistent or severe, I recommend consulting with a doctor. Would you like to book an appointment?"
    elif 'fever' in message:
        return "A fever might indicate an infection. Make sure to rest, stay hydrated, and take antipyretics if needed. If the fever persists for more than 2 days or exceeds 102°F (39°C), please consult a doctor immediately."
    elif 'cough' in message:
        return "Coughs can be caused by infections, allergies, or irritants. For a dry cough, try honey and warm water. For a productive cough, ensure you're hydrated. If it persists for more than a week or is accompanied by other symptoms, consider seeing a doctor."
    elif 'hello' in message or 'hi' in message:
        return "Hello! I'm your AI medical assistant. How can I help you today?"
    elif 'help' in message:
        return "I can help you understand common symptoms, provide basic medical advice, or assist in booking an appointment with a doctor. Please describe your symptoms or concerns."
    else:
        return "I understand you're experiencing some health concerns. Could you provide more details about your symptoms so I can better assist you? For personalized medical advice, I recommend consulting with one of our doctors."

# Routes
@app.route('/')
def index():
    return render_template('index.html')

# Authentication routes
@app.route('/api/register', methods=['POST'])
def register():
    try:
        data = request.json
        print("Incoming registration data:", data)

        if not data or 'email' not in data or 'password' not in data or 'name' not in data or 'user_type' not in data:
            return jsonify({'success': False, 'message': 'Missing required fields'}), 400

        existing_user = User.query.filter_by(email=data['email']).first()
        if existing_user:
            return jsonify({'success': False, 'message': 'Email already registered'}), 400

        hashed_password = bcrypt.generate_password_hash(data['password']).decode('utf-8')

        new_user = User(
            name=data['name'],
            email=data['email'],
            password=hashed_password,
            phone=data.get('phone', ''),
            user_type=data['user_type']
        )
        db.session.add(new_user)
        db.session.commit()

        # Add patient or doctor details
        if data['user_type'] == 'patient':
            patient_details = PatientDetail(
                patient_id=new_user.user_id,
                date_of_birth=datetime.strptime(data.get('date_of_birth', '2000-01-01'), '%Y-%m-%d').date(),
                gender=data.get('gender', ''),
                blood_group=data.get('blood_group', '')
            )
            db.session.add(patient_details)

        elif data['user_type'] == 'doctor':
            doctor_details = DoctorDetail(
                doctor_id=new_user.user_id,
                doctor_name=data['name'],
                specialization=data.get('specialization', ''),
                qualification=data.get('qualification', ''),
                experience_years=int(data.get('experience_years', 0)),
                consultation_fee=float(data.get('consultation_fee', 0.0)),
                location_id=int(data.get('location_id')) if data.get('location_id') else None
            )
            db.session.add(doctor_details)

        db.session.commit()
        return jsonify({'success': True, 'message': 'Registration successful'})

    except Exception as e:
        print("❌ Registration Error:", e)
        db.session.rollback()
        return jsonify({'success': False, 'message': str(e)}), 500



@app.route('/api/login', methods=['POST'])
def login():
    data = request.json
    
    user = User.query.filter_by(email=data['email']).first()
    
    if user and bcrypt.check_password_hash(user.password, data['password']):
        # Create session data
        session['user_id'] = user.user_id
        session['user_type'] = user.user_type
        session['name'] = user.name
        
        return jsonify({
            'success': True,
            'user': {
                'id': user.user_id,
                'name': user.name,
                'email': user.email,
                'user_type': user.user_type
            }
        })
    else:
        return jsonify({'success': False, 'message': 'Invalid email or password'}), 401

@app.route('/api/logout', methods=['POST'])
def logout():
    session.clear()
    return jsonify({'success': True})

# User profile routes
@app.route('/api/user/profile', methods=['GET'])
def get_user_profile():
    if 'user_id' not in session:
        return jsonify({'success': False, 'message': 'Not logged in'}), 401
    
    user = User.query.get(session['user_id'])
    
    if not user:
        return jsonify({'success': False, 'message': 'User not found'}), 404
    
    profile_data = {
        'id': user.user_id,
        'name': user.name,
        'email': user.email,
        'phone': user.phone,
        'user_type': user.user_type
    }
    
    # Add type-specific details
    if user.user_type == 'patient':
        patient_detail = PatientDetail.query.get(user.user_id)
        if patient_detail:
            profile_data.update({
                'date_of_birth': patient_detail.date_of_birth.strftime('%Y-%m-%d') if patient_detail.date_of_birth else None,
                'gender': patient_detail.gender,
                'blood_group': patient_detail.blood_group,
                'allergies': patient_detail.allergies,
                'chronic_conditions': patient_detail.chronic_conditions
            })
    
    elif user.user_type == 'doctor':
        doctor_detail = DoctorDetail.query.get(user.user_id)
        if doctor_detail:
            profile_data.update({
                'specialization': doctor_detail.specialization,
                'qualification': doctor_detail.qualification,
                'experience_years': doctor_detail.experience_years,
                'consultation_fee': doctor_detail.consultation_fee
            })
    
    return jsonify({'success': True, 'profile': profile_data})

# Appointment routes
@app.route('/api/appointments', methods=['GET'])
def get_appointments():
    if 'user_id' not in session:
        return jsonify({'success': False, 'message': 'Not logged in'}), 401

    user_id = session['user_id']
    user_type = session['user_type']

    appointments = []

    if user_type == 'patient':
        # Get patient's appointments
        appointment_records = Appointment.query.filter_by(patient_id=user_id).all()

        for appt in appointment_records:
            doctor = User.query.get(appt.doctor_id)
            doctor_detail = DoctorDetail.query.get(appt.doctor_id)

            hospital_location = "Not Available"
            if doctor_detail and doctor_detail.hospital:
                hospital_location = f"{doctor_detail.hospital.hospital}, {doctor_detail.hospital.location}"

            appointments.append({
                'id': appt.appointment_id,
                'date': appt.appointment_date.strftime('%Y-%m-%d'),
                'time': appt.appointment_time.strftime('%H:%M'),
                'doctor': {
                    'id': doctor.user_id,
                    'name': doctor.name,
                    'specialization': doctor_detail.specialization if doctor_detail else '',
                    'hospital_location': hospital_location  # ✅ Correct field now
                },
                'reason': appt.reason,
                'status': appt.status
            })

    elif user_type == 'doctor':
        # Get doctor's appointments
        appointment_records = Appointment.query.filter_by(doctor_id=user_id).all()

        for appt in appointment_records:
            patient = User.query.get(appt.patient_id)

            appointments.append({
                'id': appt.appointment_id,
                'date': appt.appointment_date.strftime('%Y-%m-%d'),
                'time': appt.appointment_time.strftime('%H:%M'),
                'patient': {
                    'id': patient.user_id,
                    'name': patient.name
                },
                'reason': appt.reason,
                'status': appt.status
            })

    return jsonify({'success': True, 'appointments': appointments})


@app.route('/api/appointments', methods=['POST'])
def book_appointment():
    if 'user_id' not in session or session['user_type'] != 'patient':
        return jsonify({'success': False, 'message': 'Unauthorized'}), 401
    
    data = request.json
    
    try:
        # Create the new appointment
        new_appointment = Appointment(
            patient_id=session['user_id'],
            doctor_id=data['doctor_id'],
            appointment_date=datetime.strptime(data['date'], '%Y-%m-%d').date(),
            appointment_time=datetime.strptime(data['time'], '%H:%M').time(),
            reason=data['reason'],
            status='Pending'
        )
        
        # Save the appointment to the database
        db.session.add(new_appointment)
        db.session.commit()

        # Fetch patient details (e.g., email) from the database based on session
        patient = User.query.get(session['user_id'])
        patient_email = patient.email
        # 🔍 Fetch doctor details
        doctor = User.query.get(data['doctor_id'])
        doctor_name = doctor.name if doctor else f"Doctor ID: {data['doctor_id']}"
        
        # Compose email subject and body
        subject = "Appointment Confirmation"
        body = f"""
        Dear {patient.name},

        Your appointment has been successfully booked.

        🏥 Doctor: {doctor_name}
        📆 Date: {data['date']}
        ⏰ Time Slot: {data['time']}
        🩺 Reason: {data['reason']}

        Please be on time for your appointment.

        Regards,  
        AI Healthcare Chatbot
        """

        # Send confirmation email
        if send_email(patient_email, subject, body):
            return jsonify({'success': True, 'message': 'Appointment booked and confirmation email sent successfully'})
        else:
            return jsonify({'success': True, 'message': 'Appointment booked, but failed to send confirmation email'}), 500

    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'message': str(e)}), 400

# @app.route('/api/appointments/<int:appointment_id>', methods=['PUT'])
# def update_appointment_status(appointment_id):
#     
#         return jsonify({'success': False, 'message': 'Unauthorized'}), 401
    
#     data = request.json
    
#     appointment = Appointment.query.get(appointment_id)
    
#     if not appointment:
#         return jsonify({'success': False, 'message': 'Appointment not found'}), 404
    
#     if appointment.doctor_id != session['user_id']:
#         return jsonify({'success': False, 'message': 'Unauthorized to modify this appointment'}), 403
    
#     try:
#         appointment.status = data['status']
#         db.session.commit()
        
#         return jsonify({'success': True, 'message': 'Appointment status updated'})
    
#     except Exception as e:
#         db.session.rollback()
#         return jsonify({'success': False, 'message': str(e)}), 400
@app.route('/api/appointments/<int:appointment_id>/status', methods=['POST'])
def change_appointment_status(appointment_id):
    if 'user_id' not in session or session['user_type'] != 'doctor':
        return jsonify({'success': False, 'message': 'Unauthorized'}), 401

    data = request.get_json()
    new_status = data.get('status')

    valid_statuses = ['Pending', 'Confirmed', 'Completed', 'Cancelled']
    if new_status not in valid_statuses:
        return jsonify({'success': False, 'message': 'Invalid status'}), 400

    print(" Received status update request:")
    print(f"Appointment ID: {appointment_id}")
    print(f"New Status: {new_status}")
    print(f"Doctor ID from session: {session['user_id']}")

    appointment = db.session.get(Appointment, appointment_id)
    if not appointment:
        print(" Appointment not found")
        return jsonify({'success': False, 'message': 'Appointment not found'}), 404

    if appointment.doctor_id != session['user_id']:
        print(" Unauthorized: Doctor does not own this appointment")
        return jsonify({'success': False, 'message': 'Unauthorized to modify this appointment'}), 403

    try:
        appointment.status = new_status
        db.session.commit()

        updated_appointment = db.session.get(Appointment, appointment_id)
        print(f"Status updated: {updated_appointment.status}")
        return jsonify({'success': True, 'message': 'Status updated', 'appointment': updated_appointment.status})

    except Exception as e:
        db.session.rollback()
        print(" DB Error:", str(e))
        return jsonify({'success': False, 'message': str(e)}), 400




# Doctor listing route
@app.route('/api/doctors', methods=['GET'])
def get_doctors():
    doctors = []

    doctor_users = User.query.filter_by(user_type='doctor').all()

    for doctor in doctor_users:
        doctor_detail = DoctorDetail.query.get(doctor.user_id)

        if doctor_detail:
            # Safely get hospital info
            hospital_name = 'N/A'
            if doctor_detail.hospital:
                hospital_name = doctor_detail.hospital.hospital or doctor_detail.hospital.location

            doctors.append({
                'id': doctor.user_id,
                'name': doctor.name,
                'specialization': doctor_detail.specialization,
                'qualification': doctor_detail.qualification,
                'experience_years': doctor_detail.experience_years,
                'consultation_fee': doctor_detail.consultation_fee,
                'hospital_location': hospital_name
            })

    return jsonify({'success': True, 'doctors': doctors})

@app.route('/api/hospitals', methods=['GET'])
def get_hospitals():
    hospitals = HospitalLocation.query.all()
    hospital_list = [{'id': h.id, 'name': f"{h.hospital}, {h.location}"} for h in hospitals]
    return jsonify({'success': True, 'hospitals': hospital_list})

# AI Chatbot route
@app.route('/api/chat', methods=['POST'])
def chat_with_bot():
    if 'user_id' not in session:
        return jsonify({'success': False, 'message': 'Not logged in'}), 401
    
    data = request.json
    user_message = data['message']
    
    # Save user message
    new_message = ChatMessage(
        user_id=session['user_id'],
        message_text=user_message,
        is_bot_message=False
    )
    db.session.add(new_message)
    
    # Generate AI response
    bot_response = generate_ai_response(user_message)
    
    # Save bot response
    bot_message = ChatMessage(
        user_id=session['user_id'],
        message_text=bot_response,
        is_bot_message=True
    )
    db.session.add(bot_message)
    
    db.session.commit()
    
    return jsonify({'success': True, 'response': bot_response})

@app.route('/api/chat/history', methods=['GET'])
def get_chat_history():
    if 'user_id' not in session:
        return jsonify({'success': False, 'message': 'Not logged in'}), 401
    
    messages = ChatMessage.query.filter_by(user_id=session['user_id']).order_by(ChatMessage.created_at).all()
    
    chat_history = []
    
    for message in messages:
        chat_history.append({
            'text': message.message_text,
            'is_bot': message.is_bot_message,
            'timestamp': message.created_at.strftime('%Y-%m-%d %H:%M:%S')
        })
    
    return jsonify({'success': True, 'history': chat_history})

# Contact form route
@app.route('/api/contact', methods=['POST'])
def submit_contact_form():
    data = request.json

    try:
        new_message = ContactMessage(
            name=data['name'],
            email=data['email'],
            subject=data['subject'],
            message=data['message']
        )

        db.session.add(new_message)
        db.session.commit()

        # Send confirmation email to admin or user
        subject = f"New Contact Message from {data['name']}"
        body = f"Name: {data['name']}\nEmail: {data['email']}\nSubject: {data['subject']}\n\nMessage:\n{data['message']}"
        send_email('someone@gmail.com', subject, body)  # or send to the user
        send_email(data['email'], "We've received your message", f"Hi {data['name']},\n\nThanks for reaching out to us. We will get back to you soon.\n\n- MediChat Team")
        return jsonify({'success': True, 'message': 'Message sent successfully'})

    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'message': str(e)}), 400


# Patient listing for doctors
@app.route('/api/doctor/patients', methods=['GET'])
def get_doctor_patients():
    if 'user_id' not in session or session['user_type'] != 'doctor':
        return jsonify({'success': False, 'message': 'Unauthorized'}), 401
    
    doctor_id = session['user_id']
    
    # Find all patients who have appointments with this doctor
    patient_ids = db.session.query(Appointment.patient_id).filter_by(doctor_id=doctor_id).distinct().all()
    patient_ids = [pid[0] for pid in patient_ids]
    
    patients = []
    
    for pid in patient_ids:
        patient = User.query.get(pid)
        patient_detail = PatientDetail.query.get(pid)
        
        # Get last appointment date
        last_appointment = Appointment.query.filter_by(
            patient_id=pid, 
            doctor_id=doctor_id,
            status='Completed'
        ).order_by(Appointment.appointment_date.desc()).first()
        
        patient_data = {
            'id': patient.user_id,
            'name': patient.name,
            'gender': patient_detail.gender if patient_detail else None,
            'age': None,
            'last_visit': last_appointment.appointment_date.strftime('%Y-%m-%d') if last_appointment else None
        }
        
        # Calculate age if date of birth is available
        if patient_detail and patient_detail.date_of_birth:
            today = datetime.now().date()
            age = today.year - patient_detail.date_of_birth.year
            if (today.month, today.day) < (patient_detail.date_of_birth.month, patient_detail.date_of_birth.day):
                age -= 1
            patient_data['age'] = age
        
        patients.append(patient_data)
    
    return jsonify({'success': True, 'patients': patients})

@app.route('/api/doctor/appointments', methods=['GET'])
def get_doctor_appointments():
    if 'user_id' not in session or session['user_type'] != 'doctor':
        return jsonify({'success': False, 'message': 'Unauthorized'}), 401

    doctor_id = session['user_id']
    appointments = Appointment.query.filter_by(doctor_id=doctor_id).order_by(Appointment.appointment_date.desc()).all()

    result = []
    for appt in appointments:
        patient = User.query.get(appt.patient_id)
        result.append({
            'id': appt.appointment_id,
            'date': appt.appointment_date.strftime('%Y-%m-%d'),
            'time': appt.appointment_time.strftime('%H:%M'),
            'reason': appt.reason,
            'status': appt.status,
            'patient_name': patient.name if patient else 'Unknown'
        })

    return jsonify({'success': True, 'appointments': result})

# Medical records routes
@app.route('/api/records', methods=['POST'])
def create_medical_record():
    if 'user_id' not in session or session['user_type'] != 'doctor':
        return jsonify({'success': False, 'message': 'Unauthorized'}), 401
    
    data = request.json
    
    try:
        new_record = MedicalRecord(
            patient_id=data['patient_id'],
            doctor_id=session['user_id'],
            appointment_id=data.get('appointment_id'),
            diagnosis=data['diagnosis'],
            prescription=data.get('prescription', ''),
            notes=data.get('notes', '')
        )
        
        db.session.add(new_record)
        
        # Update appointment status if provided
        if data.get('appointment_id'):
            appointment = Appointment.query.get(data['appointment_id'])
            if appointment:
                appointment.status = 'Completed'
        
        db.session.commit()
        
        return jsonify({'success': True, 'message': 'Medical record created successfully'})
    
    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'message': str(e)}), 400

@app.route('/api/records/patient/<int:patient_id>', methods=['GET'])
def get_patient_records(patient_id):
    if 'user_id' not in session:
        return jsonify({'success': False, 'message': 'Not logged in'}), 401
    
    # Patients can only access their own records
    if session['user_type'] == 'patient' and session['user_id'] != patient_id:
        return jsonify({'success': False, 'message': 'Unauthorized'}), 403
    
    # Doctors can only access records of their patients
    if session['user_type'] == 'doctor':
        # Check if this patient has had appointments with this doctor
        has_appointment = Appointment.query.filter_by(
            patient_id=patient_id, 
            doctor_id=session['user_id']
        ).first() is not None
        
        if not has_appointment:
            return jsonify({'success': False, 'message': 'Unauthorized'}), 403
    
    records = MedicalRecord.query.filter_by(patient_id=patient_id).order_by(MedicalRecord.created_at.desc()).all()
    
    medical_records = []
    
    for record in records:
        doctor = User.query.get(record.doctor_id)
        
        medical_records.append({
            'id': record.record_id,
            'date': record.created_at.strftime('%Y-%m-%d'),
            'doctor': {
                'id': doctor.user_id,
                'name': doctor.name
            },
            'diagnosis': record.diagnosis,
            'prescription': record.prescription,
            'notes': record.notes
        })
    
    return jsonify({'success': True, 'records': medical_records})

# Main entry point
# Main entry point
if __name__ == '__main__':

     # ✅ Test MySQL connection
    conn = create_connection()
    if conn:
        conn.close()
    # Create tables if they don't exist
    with app.app_context():
        db.create_all()
    


    # Run the app
    app.run(debug=True, host='127.0.0.1', port=5000, use_reloader=False)

