from rest_framework import status
from rest_framework.decorators import api_view
from rest_framework.response import Response

from api.branch.models import Branch
from .models import Department
from .serializers import DepartmentSerializer


@api_view(['GET', 'POST'])
def department_list_create(request):
    """
    GET: List all departments (optional filter: ?branch_id=).
    POST: Create a department (CEO or Manager).
    """
    if request.method == 'GET':
        queryset = Department.objects.select_related('branch').all().order_by('-created_at')
        branch_id = request.query_params.get('branch_id')
        if branch_id:
            queryset = queryset.filter(branch_id=branch_id)
        serializer = DepartmentSerializer(queryset, many=True)
        return Response(serializer.data)

    elif request.method == 'POST':
        if getattr(request.user, 'role', '') not in ['ceo', 'manager']:
            return Response({"error": "Only CEO or Manager can create departments."}, status=status.HTTP_403_FORBIDDEN)

        branch_id = request.data.get('branch')
        if not branch_id:
            return Response({"error": "Branch is required."}, status=status.HTTP_400_BAD_REQUEST)

        try:
            branch = Branch.objects.get(pk=branch_id)
        except Branch.DoesNotExist:
            return Response({"error": "Selected branch does not exist."}, status=status.HTTP_400_BAD_REQUEST)

        name = request.data.get('name', '').strip()
        if not name:
            return Response({"error": "Department name is required."}, status=status.HTTP_400_BAD_REQUEST)

        if Department.objects.filter(branch=branch, name__iexact=name).exists():
            return Response({"error": f"A department named '{name}' already exists in this branch."}, status=status.HTTP_400_BAD_REQUEST)

        serializer = DepartmentSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save(created_by=request.user.firebase_uid, branch=branch)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET', 'PATCH', 'DELETE'])
def department_detail(request, pk):
    """Retrieve, update, or delete a department."""
    try:
        department = Department.objects.select_related('branch').get(pk=pk)
    except Department.DoesNotExist:
        return Response({"error": "Department not found"}, status=status.HTTP_404_NOT_FOUND)

    if request.method == 'GET':
        serializer = DepartmentSerializer(department)
        return Response(serializer.data)

    if getattr(request.user, 'role', '') not in ['ceo', 'manager']:
        return Response({"error": "Only CEO or Manager can modify departments."}, status=status.HTTP_403_FORBIDDEN)

    if request.method == 'PATCH':
        serializer = DepartmentSerializer(department, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    elif request.method == 'DELETE':
        department.delete()
        return Response({"message": "Department deleted successfully"}, status=status.HTTP_200_OK)
