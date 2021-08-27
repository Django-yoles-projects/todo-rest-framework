from django.shortcuts import render
from rest_framework import viewsets
from .models import Todo, TodoList
from .serializers import TodoSerializer, TodoListSerializer

class TodoViewSet(viewsets.ModelViewSet):
    queryset = Todo.objects.all()
    serializer_class = TodoSerializer 


class TodoListViewSet(viewsets.ModelViewSet):
    queryset = TodoList.objects.all()
    serializer_class = TodoListSerializer 