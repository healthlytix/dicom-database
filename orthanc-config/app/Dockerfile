# External Authorization Service 

FROM python:3.11.11-slim

ENV PYTHONUNBUFFERED=1

COPY requirements.txt /
RUN pip install -r requirements.txt && mkdir /orthanc_auth_service
COPY orthanc_auth_service /orthanc_auth_service

WORKDIR /orthanc_auth_service
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port" , "8000"]


